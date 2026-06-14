module Components.ExerciseTimer
  ( ExerciseTimerProps
  , mkExerciseTimer
  ) where

import Prelude

import Beta.DOM as R
import Data.Int as Int
import Data.Maybe (fromMaybe)
import Effect (Effect)
import React.Basic (JSX)
import React.Basic.DOM.Events (targetValue)
import React.Basic.Events (handler, handler_)
import React.Basic.Hooks (Component, component, useEffect, useState', (/\))
import React.Basic.Hooks as React

type ExerciseTimerProps =
  { exerciseTitle :: String
  }

data ActiveChoice
  = Preset
  | Custom

derive instance Eq ActiveChoice

data TimerStatus
  = Idle
  | Running
  | Paused
  | Done

derive instance Eq TimerStatus

newtype Minutes = Minutes Int

derive newtype instance eqMinutes :: Eq Minutes
derive newtype instance ordMinutes :: Ord Minutes

foreign import data IntervalId :: Type

foreign import nowMillis :: Effect Number
foreign import setTimerInterval :: Effect Unit -> Effect IntervalId
foreign import clearTimerInterval :: IntervalId -> Effect Unit
foreign import requestNotificationPermission :: Effect Unit
foreign import notifyDone :: String -> Effect Unit

presets :: Array Minutes
presets = [ Minutes 1, Minutes 5, Minutes 10 ]

defaultMinutes :: Minutes
defaultMinutes = Minutes 5

minCustomMinutes :: Minutes
minCustomMinutes = Minutes 1

maxCustomMinutes :: Minutes
maxCustomMinutes = Minutes 180

minutesToInt :: Minutes -> Int
minutesToInt (Minutes value) = value

minutesToSeconds :: Minutes -> Int
minutesToSeconds (Minutes value) = value * 60

minutesToMilliseconds :: Minutes -> Number
minutesToMilliseconds (Minutes value) = Int.toNumber value * 60000.0

mkExerciseTimer :: Component ExerciseTimerProps
mkExerciseTimer =
  component "ExerciseTimer" \{ exerciseTitle } -> React.do
    presetMinutes /\ setPresetMinutes <- useState' defaultMinutes
    customMinutes /\ setCustomMinutes <- useState' ""
    activeChoice /\ setActiveChoice <- useState' Preset
    status /\ setStatus <- useState' Idle
    controlsOpen /\ setControlsOpen <- useState' false
    targetEpoch /\ setTargetEpoch <- useState' 0.0
    remainingSeconds /\ setRemainingSeconds <- useState' (minutesToSeconds defaultMinutes)

    let
      shellClasses =
        "fixed bottom-4 right-4 z-40 flex w-auto max-w-[calc(100vw-2rem)] flex-wrap "
          <> "items-center justify-end gap-1 rounded-full border border-[var(--color-border)] "
          <> "bg-white/95 px-3 py-2 text-center shadow-[0_18px_45px_rgba(15,23,42,0.14)] "
          <> "backdrop-blur transition-[width,max-width,box-shadow] duration-300 ease-out "
          <>
            "sm:bottom-5 sm:right-5"

      selectedMinutes =
        case activeChoice of
          Preset -> presetMinutes
          Custom -> customMinutesValue customMinutes

      isDone = status == Done
      isRunning = status == Running
      isTiming = status == Running || status == Paused
      clock = formatClock remainingSeconds

      setControlsVisible visible = setControlsOpen visible

      startTimer = do
        let duration = selectedMinutes
        when (activeChoice == Custom) (setCustomMinutes (show (minutesToInt duration)))
        setRemainingSeconds (minutesToSeconds duration)
        setTargetEpoch =<< durationToTarget duration
        setStatus Running
        setControlsOpen false
        requestNotificationPermission

      resetTimer = do
        setStatus Idle
        setControlsOpen false

      pauseTimer = do
        setRemainingSeconds =<< remainingFromTarget targetEpoch
        setStatus Paused

      resumeTimer = do
        setTargetEpoch =<< secondsToTarget remainingSeconds
        setStatus Running

      choosePreset minutes = do
        setPresetMinutes minutes
        setActiveChoice Preset
        when isDone (setStatus Idle)

      chooseCustom value = do
        setCustomMinutes value
        setActiveChoice (if value == "" then Preset else Custom)
        when isDone (setStatus Idle)

    useEffect (status /\ targetEpoch) do
      if status == Running then do
        intervalId <- setTimerInterval do
          remaining <- remainingFromTarget targetEpoch
          setRemainingSeconds remaining
          when (remaining <= 0) do
            setStatus Done
            setControlsOpen false
            notifyDone exerciseTitle
        pure (clearTimerInterval intervalId)
      else
        pure (pure unit)

    pure $
      R.section
        { className: shellClasses
        , "aria-label": "Exercise timer"
        , onMouseEnter: handler_ (setControlsVisible true)
        , onMouseLeave: handler_ (setControlsVisible false)
        , onPointerEnter: handler_ (setControlsVisible true)
        , onPointerLeave: handler_ (setControlsVisible false)
        , onFocus: handler_ (setControlsVisible true)
        , onClick: handler_ (when isTiming (setControlsVisible true))
        , tabIndex: 0
        }
        [ if isTiming || isDone then
            R.div
              { className:
                  "min-w-[4.35rem] text-center font-sans text-[1.45rem] font-black "
                    <> "leading-none tabular-nums tracking-[-0.04em] "
                    <>
                      (if isDone then "text-[var(--color-button)]" else "text-[var(--color-heading-black)]")
              , "aria-live": "polite"
              }
              [ R.text clock ]
          else
            R.text ""
        , if status == Idle then
            R.div
              { className: "flex flex-wrap items-center justify-end gap-1" }
              (map (presetButton presetMinutes activeChoice choosePreset) presets <> [ customInput activeChoice customMinutes chooseCustom ])
          else
            R.text ""
        , if status == Idle then
            R.button
              { type: "button"
              , className: primaryButtonClasses
              , onClick: handler_ startTimer
              }
              [ R.text "Start" ]
          else
            R.text ""
        , if isTiming then
            runningControls controlsOpen isRunning pauseTimer resumeTimer startTimer resetTimer
          else
            R.text ""
        , if isDone then
            doneControls startTimer resetTimer
          else
            R.text ""
        ]
  where
  customMinutesValue :: String -> Minutes
  customMinutesValue =
    clampMinutes <<< Minutes <<< fromMaybe (minutesToInt minCustomMinutes) <<< Int.fromString
    where
    clampMinutes :: Minutes -> Minutes
    clampMinutes value = max minCustomMinutes (min maxCustomMinutes value)

  remainingFromTarget :: Number -> Effect Int
  remainingFromTarget targetEpoch = do
    now <- nowMillis
    pure (max 0 (Int.ceil ((targetEpoch - now) / 1000.0)))

  durationToTarget :: Minutes -> Effect Number
  durationToTarget minutes = do
    now <- nowMillis
    pure (now + minutesToMilliseconds minutes)

  secondsToTarget :: Int -> Effect Number
  secondsToTarget seconds = do
    now <- nowMillis
    pure (now + Int.toNumber (max 0 seconds) * 1000.0)

  formatClock :: Int -> String
  formatClock totalSeconds =
    let
      safeSeconds = max 0 totalSeconds
      hours = safeSeconds `Int.quot` 3600
      minutes = (safeSeconds `Int.rem` 3600) `Int.quot` 60
      seconds = safeSeconds `Int.rem` 60
      twoDigits value =
        if value < 10 then "0" <> show value else show value
    in
      if hours > 0 then
        show hours <> ":" <> twoDigits minutes <> ":" <> twoDigits seconds
      else
        twoDigits minutes <> ":" <> twoDigits seconds

primaryButtonClasses :: String
primaryButtonClasses =
  "btn btn-xs min-h-7 rounded-full border-0 bg-[var(--color-button)] px-3.5 " <>
    "font-sans text-xs text-white shadow-none hover:bg-[var(--color-red-salsa)]"

outlineButtonClasses :: String
outlineButtonClasses =
  "btn btn-xs btn-outline min-h-7 rounded-full border-[var(--color-border)] px-3 " <>
    "font-sans text-xs text-[var(--color-heading-black)]"

presetButton :: Minutes -> ActiveChoice -> (Minutes -> Effect Unit) -> Minutes -> JSX
presetButton selectedPreset activeChoice choosePreset minutes =
  R.button
    { type: "button"
    , className: presetButtonClasses (activeChoice == Preset && selectedPreset == minutes)
    , onClick: handler_ (choosePreset minutes)
    }
    [ R.text (minutesLabel minutes) ]
  where
  minutesLabel :: Minutes -> String
  minutesLabel duration = show (minutesToInt duration) <> " min"

  presetButtonClasses :: Boolean -> String
  presetButtonClasses isSelected =
    if isSelected then
      "btn btn-xs min-h-7 rounded-full border border-[var(--color-border)] "
        <> "bg-[var(--color-surface-soft)] px-2.5 font-sans text-xs text-[var(--color-heading-black)] "
        <>
          "shadow-none hover:border-[var(--color-border)] hover:bg-[var(--color-surface-soft)]"
    else
      "btn btn-xs btn-ghost min-h-7 rounded-full px-2.5 font-sans text-xs "
        <> "text-[var(--color-text-light)] hover:bg-[var(--color-surface-soft)] "
        <>
          "hover:text-[var(--color-heading-black)]"

customInput :: ActiveChoice -> String -> (String -> Effect Unit) -> JSX
customInput activeChoice customMinutes chooseCustom =
  R.label
    { className: customInputClasses (activeChoice == Custom) }
    [ R.input
        { type: "number"
        , value: customMinutes
        , placeholder: "custom"
        , onFocus: handler_ (when (customMinutes /= "") (chooseCustom customMinutes))
        , onChange: handler targetValue \value -> chooseCustom (fromMaybe "" value)
        , className:
            "w-14 min-w-0 bg-transparent text-center text-xs font-bold text-[var(--color-heading-black)] " <>
              "outline-none placeholder:font-medium placeholder:text-[var(--color-text-light)]"
        , "aria-label": "Custom timer minutes"
        }
    , R.span { className: "text-[0.68rem]" } [ R.text "m" ]
    ]
  where
  customInputClasses :: Boolean -> String
  customInputClasses isSelected =
    "input input-bordered input-xs flex h-7 min-h-7 w-24 items-center gap-1 rounded-full "
      <> "border-[var(--color-border)] px-2 font-sans text-[var(--color-text-light)] shadow-none "
      <>
        (if isSelected then "bg-[var(--color-surface-soft)]" else "bg-white")

runningControls
  :: Boolean
  -> Boolean
  -> Effect Unit
  -> Effect Unit
  -> Effect Unit
  -> Effect Unit
  -> JSX
runningControls controlsOpen isRunning pauseTimer resumeTimer startTimer resetTimer =
  R.div
    { className: controlsClasses controlsOpen
    , "aria-hidden": not controlsOpen
    }
    [ R.button
        { type: "button"
        , className: outlineButtonClasses
        , onClick: handler_ (if isRunning then pauseTimer else resumeTimer)
        , tabIndex: if controlsOpen then 0 else -1
        }
        [ R.text (if isRunning then "Pause" else "Resume") ]
    , R.button
        { type: "button"
        , className: primaryButtonClasses
        , onClick: handler_ startTimer
        , tabIndex: if controlsOpen then 0 else -1
        }
        [ R.text "Restart" ]
    , R.button
        { type: "button"
        , className: outlineButtonClasses
        , onClick: handler_ resetTimer
        , tabIndex: if controlsOpen then 0 else -1
        }
        [ R.text "Stop" ]
    ]
  where
  controlsClasses :: Boolean -> String
  controlsClasses isOpen =
    "flex items-center gap-1.5 overflow-hidden transition-[max-width,opacity,transform] "
      <> "duration-300 ease-out "
      <>
        if isOpen then
          "max-w-[16rem] translate-x-0 opacity-100"
        else
          "pointer-events-none max-w-0 translate-x-2 opacity-0"

doneControls :: Effect Unit -> Effect Unit -> JSX
doneControls startTimer resetTimer =
  R.div
    { className: "flex items-center gap-1.5" }
    [ R.button
        { type: "button"
        , className: primaryButtonClasses
        , onClick: handler_ startTimer
        }
        [ R.text "Start again" ]
    , R.button
        { type: "button"
        , className: outlineButtonClasses
        , onClick: handler_ resetTimer
        }
        [ R.text "Stop" ]
    ]
