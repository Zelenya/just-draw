module App
  ( AppEnv
  , mkApp
  ) where

import Prelude

import App.Path (BasePath, RoutePath(..), nonEmptyRoutePath, rootPath, tagPath, withBasePath)
import App.Route (Route(..), parsePath)
import Beta.DOM as R
import Components.ExerciseTimer (mkExerciseTimer)
import Components.Icon (house, makeIcon)
import Content (ContentBlock(..), ContentImage, ContentInline(..), ContentLink, Exercise, Tag, exercises, site, tags)
import Data.Array as Array
import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (un)
import Effect (Effect)
import Effect.Random (randomInt)
import React.Basic (JSX)
import React.Basic.DOM.Events (targetValue)
import React.Basic.Events (handler)
import React.Basic.Hooks (Component, component, useEffectOnce, useState', (/\))
import React.Basic.Hooks as React

type AppEnv =
  { basePath :: BasePath
  , pathname :: RoutePath
  }

mkApp :: Component AppEnv
mkApp = do
  exerciseTimer <- mkExerciseTimer
  component "App" \{ basePath, pathname } ->
    React.do
      let
        defaultLuckyHref =
          case Array.head exercises of
            Just exercise -> withBasePath basePath exercise.slug
            Nothing -> withBasePath basePath rootPath

      selectedTag /\ setSelectedTag <- useState' (Nothing :: Maybe RoutePath)
      luckyHref /\ setLuckyHref <- useState' defaultLuckyHref

      useEffectOnce do
        case Array.length exercises of
          0 -> pure unit
          count -> do
            index <- randomInt 0 (count - 1)
            case Array.index exercises index of
              Just exercise -> setLuckyHref (withBasePath basePath exercise.slug)
              Nothing -> pure unit
        pure (pure unit)

      let
        route = parsePath basePath pathname

      pure
        case route of
          Home ->
            { basePath
            , selectedTag
            , setSelectedTag
            , luckyHref
            } # homePage # homeLayout
          Exercise slugSegment ->
            innerLayout basePath
              case Array.find (\exercise -> exercise.slugSegment == slugSegment) exercises of
                Just exercise -> exercisePage exerciseTimer basePath exercise
                Nothing -> notFoundPage basePath
          Tag tagName ->
            innerLayout basePath
              case Array.find (\tag -> tag.name == tagName) tags of
                Just tag -> tagPage basePath tag
                Nothing -> notFoundPage basePath
          NotFound ->
            innerLayout basePath $ notFoundPage basePath
  where
  homeLayout :: JSX -> JSX
  homeLayout page = R.div
    { className: "mx-auto min-h-screen max-w-[72rem] px-4 sm:px-5" }
    [ R.main
        { className: "flex min-h-screen w-full items-center justify-center" }
        [ page ]
    ]

  innerLayout :: BasePath -> JSX -> JSX
  innerLayout basePath page = R.div
    { className: "mx-auto min-h-screen max-w-[72rem] px-4 sm:px-5" }
    [ R.div
        { className: "w-full min-h-screen py-8 pb-12" }
        [ R.header
            { className: "mb-10" }
            [ R.a
                { href: withBasePath basePath rootPath
                , className: "font-sans text-[1.15rem] font-bold text-[var(--color-heading-black)] no-underline"
                }
                [ R.text site.title ]
            ]
        , R.main { className: "w-full" } [ page ]
        ]
    ]

homePage
  :: { basePath :: BasePath
     , selectedTag :: Maybe RoutePath
     , setSelectedTag :: Maybe RoutePath -> Effect Unit
     , luckyHref :: String
     }
  -> JSX
homePage { basePath, selectedTag, setSelectedTag, luckyHref } =
  R.section
    { className: "mx-auto flex w-full max-w-[38rem] flex-col items-center justify-center py-16 text-center sm:py-24" }
    [ R.h1
        { className: "mb-8 mt-0 text-[clamp(3.2rem,9vw,5.75rem)] leading-[0.95] font-black tracking-[-0.055em] text-[var(--color-heading-black)]" }
        [ R.text site.title ]
    , R.div
        { className: "card w-full max-w-[34rem] rounded-[1.75rem] border border-[var(--color-border)] bg-white/95 px-4 py-4 shadow-[var(--shadow-soft)] sm:px-5 sm:py-5" }
        [ R.div
            { className: "flex flex-col items-center justify-center gap-3 sm:flex-row" }
            [ R.span
                { className: "font-sans text-[1.05rem] font-bold text-[var(--color-heading)]" }
                [ R.text "I want to practice" ]
            , R.select
                { className: "select select-bordered w-full min-w-[13rem] rounded-full border-[var(--color-border)] bg-[var(--color-surface-soft)] pr-9 font-sans text-[var(--color-heading)] shadow-none focus:border-[rgba(239,71,103,0.6)] focus:outline-none focus:shadow-[0_0_0_4px_rgba(239,71,103,0.12)] sm:w-auto"
                , value: selectedTagValue
                , onChange: handler targetValue \value -> setSelectedTag (nonEmptyRoutePath (fromMaybe "" value))
                }
                ([ R.option { value: "" } [ R.text "Select a tag" ] ] <> map tagOption tags)
            ]
        , R.div
            { className: "mt-4 flex flex-wrap justify-center gap-3" }
            [ case selectedTag of
                Nothing ->
                  actionLink luckyHref "I'm feeling lucky"
                Just _ ->
                  -- Make it less confusing, otherwise two active action buttons are overwhelming
                  disabledActionButton "I'm feeling lucky"
            , case selectedTag of
                Nothing ->
                  disabledActionButton "Practice"
                Just selectedTagPath ->
                  actionLink (withBasePath basePath selectedTagPath) "Practice"
            ]
        ]
    ]
  where
  selectedTagValue = case selectedTag of
    Nothing -> ""
    Just selectedTagPath -> un RoutePath selectedTagPath

  tagOption :: Tag -> JSX
  tagOption tag = R.option { value: un RoutePath tag.path } [ R.text tag.name ]

exercisePage :: ({ exerciseTitle :: String } -> JSX) -> BasePath -> Exercise -> JSX
exercisePage exerciseTimer basePath exercise = R.div
  { className: "mx-auto max-w-[44rem]" }
  [ R.header
      { className: "text-center" }
      [ R.h2
          { className: "mb-3 mt-0"
          , itemProp: "headline"
          }
          [ R.text exercise.title ]
      ]
  , R.section
      { className: "mb-6" }
      [ R.div
          { className: "flex flex-wrap justify-center gap-2" }
          (map (\tagName -> tagChip basePath tagName) exercise.tags)
      ]
  , exerciseTimer { exerciseTitle: exercise.title }
  , R.article
      { className: "px-1 py-2 sm:px-0 sm:py-4" }
      [ R.div { className: "[&>:first-child]:mt-0" } (map renderContentBlock exercise.body) ]
  , R.div
      { className: "mt-6 flex flex-wrap justify-center gap-3" }
      ( [ homeLink (withBasePath basePath rootPath) ]
          <> map (\tagName -> tagChip basePath tagName) exercise.tags
      )
  ]

tagPage :: BasePath -> Tag -> JSX
tagPage basePath tag = R.div
  { className: "mx-auto max-w-[70rem]" }
  [ R.header
      { className: "relative z-20 mb-6 flex items-center justify-center gap-2 text-center" }
      [ R.h1 { className: "m-0" } [ R.text tag.name ]
      , if tag.description == defaultDescription then
          R.text ""
        else
          R.div
            { className: "dropdown dropdown-hover dropdown-end" }
            [ R.button
                { className: "btn btn-circle btn-ghost btn-sm font-sans text-[var(--color-text-light)]"
                , "aria-label": tag.description
                , type: "button"
                }
                [ R.text "?" ]
            , R.div
                { className: "dropdown-content z-50 mt-2 w-72 max-w-[calc(100vw-2rem)] rounded-box bg-base-100 p-4 text-left font-serif text-sm leading-relaxed text-[var(--color-text)] shadow-xl"
                }
                [ R.text tag.description ]
            ]
      ]
  , R.ol { className: "m-0 grid list-none gap-5 p-0 md:grid-cols-2 xl:grid-cols-3" }
      (map (exercisePreviewCard basePath) matchingExercises)
  ]
  where
  matchingExercises = Array.filter (\exercise -> Array.elem tag.name exercise.tags) exercises
  defaultDescription = "Exercises tagged " <> tag.name <> "."

notFoundPage :: BasePath -> JSX
notFoundPage basePath = R.section
  { className: "mx-auto flex max-w-[44rem] justify-center" }
  [ R.div
      { className: cardClasses }
      [ R.div
          { className: "card-body items-center px-6 py-8 text-center" }
          [ R.h1 { className: "mt-0" } [ R.text "404: Not Found" ]
          , R.p { className: "mb-0" } [ R.text "That page does not exist." ]
          , actionLink (withBasePath basePath rootPath) "Go home"
          ]
      ]
  ]
  where
  cardClasses =
    "card w-full max-w-[28rem] overflow-hidden rounded-[1.5rem] border "
      <> "border-[var(--color-border)] bg-[var(--color-surface)] shadow-[var(--shadow-card)]"

tagChip :: BasePath -> String -> JSX
tagChip basePath tagName = R.a
  { href: withBasePath basePath (tagPath tagName)
  , className: tagChipClasses
  }
  [ R.text tagName ]
  where
  tagChipClasses =
    "badge badge-outline m-0 inline-flex h-auto items-center justify-center rounded-full "
      <> "border-[var(--color-button)] bg-transparent px-[0.7rem] py-[0.3rem] text-[0.82rem] "
      <> "font-medium leading-[1.4] text-[var(--color-button)] no-underline shadow-none "
      <>
        "hover:border-[var(--color-red-salsa)] hover:bg-[var(--color-red-salsa)] hover:text-white"

homeLink :: String -> JSX
homeLink href = R.a
  { href
  , className: homeChipClasses
  , "aria-label": "Back home"
  , title: "Back home"
  }
  [ makeIcon house { className: "h-3.5 w-3.5" } ]
  where
  homeChipClasses =
    "badge badge-outline m-0 inline-flex h-auto items-center justify-center rounded-full "
      <> "border-[var(--color-button)] bg-transparent px-[0.7rem] py-[0.3rem] font-sans "
      <> "text-[0.82rem] font-bold leading-[1.4] text-[var(--color-button)] no-underline shadow-none "
      <>
        "hover:border-[var(--color-red-salsa)] hover:bg-[var(--color-red-salsa)] hover:text-white"

exercisePreviewCard :: BasePath -> Exercise -> JSX
exercisePreviewCard basePath exercise = R.li
  { className: "m-0" }
  [ R.article
      { className: previewCardClasses
      }
      [ R.a
          { href: exerciseHref
          , className: "block text-inherit no-underline"
          , itemProp: "url"
          }
          [ case exercise.heroImage of
              Just heroImage ->
                R.div
                  { className: "h-48 overflow-hidden bg-[linear-gradient(135deg,rgba(239,71,103,0.14),rgba(0,91,153,0.14))] sm:h-52" }
                  [ R.img
                      { className: "h-full w-full object-cover"
                      , src: heroImage
                      , alt: exercise.title
                      }
                  ]
              Nothing ->
                R.div
                  { className: "h-48 bg-[linear-gradient(135deg,rgba(239,71,103,0.14),rgba(0,91,153,0.14))] sm:h-52"
                  , "aria-hidden": true
                  }
                  []
          ]
      , R.div
          { className: "card-body gap-4 px-5 py-5 sm:px-6 sm:py-5" }
          [ R.h2
              { className: "m-0 text-left text-2xl"
              }
              [ R.a
                  { href: exerciseHref
                  , className: "text-inherit no-underline"
                  }
                  [ R.span { itemProp: "headline" } [ R.text exercise.title ] ]
              ]
          , R.div
              { className: "flex flex-col gap-3" }
              [ R.p
                  { className: "m-0 leading-[1.6] text-[var(--color-text-light)]" }
                  [ R.text exercise.excerpt ]
              , R.div
                  { className: "flex flex-wrap justify-center gap-2" }
                  (map (\tagName -> tagChip basePath tagName) exercise.tags)
              ]
          ]
      ]
  ]
  where
  exerciseHref = withBasePath basePath exercise.slug

  previewCardClasses =
    "card overflow-hidden rounded-[1.5rem] border border-[var(--color-border)] "
      <> "bg-[var(--color-surface)] text-inherit shadow-[var(--shadow-card)] transition "
      <> "duration-200 hover:-translate-y-0.5 hover:border-[rgba(239,71,103,0.35)] "
      <>
        "hover:shadow-[0_18px_36px_rgba(15,23,42,0.12)]"

actionLink :: String -> String -> JSX
actionLink href label = R.a
  { href
  , className: primaryButtonClasses
  }
  [ R.span {} [ R.text label ] ]
  where
  primaryButtonClasses =
    "btn min-h-11 rounded-full border-0 bg-[var(--color-button)] px-[1.15rem] "
      <> "text-white no-underline shadow-none transition-[background-color,transform,box-shadow] duration-200 "
      <> "hover:-translate-y-px hover:bg-[var(--color-red-salsa)] hover:text-white "
      <> "hover:shadow-[0_12px_20px_rgba(227,77,76,0.18)] focus:bg-[var(--color-red-salsa)] "
      <>
        "focus:text-white focus:shadow-[0_12px_20px_rgba(227,77,76,0.18)]"

disabledActionButton :: String -> JSX
disabledActionButton label = R.button
  { className: disabledButtonClasses
  , disabled: true
  }
  [ R.span {} [ R.text label ] ]
  where
  disabledButtonClasses =
    "btn min-h-11 rounded-full border-0 bg-[#d5dbe4] px-[1.15rem] text-white shadow-none "
      <> "disabled:pointer-events-none disabled:cursor-default disabled:bg-[#c3c9d3] "
      <>
        "disabled:text-white disabled:shadow-none"

renderContentBlock :: ContentBlock -> JSX
renderContentBlock = case _ of
  Heading level text ->
    case level of
      4 -> R.h4 { className: "text-[1.44rem]" } [ R.text text ]
      5 -> R.h5 {} [ R.text text ]
      6 -> R.h6 {} [ R.text text ]
      _ -> R.h3 { className: "text-[1.728rem]" } [ R.text text ]
  Paragraph text ->
    R.p {} [ R.text text ]
  Quote text ->
    R.blockquote {} [ R.p {} [ R.text text ] ]
  List items ->
    R.ul {} (map (\item -> R.li {} (map renderContentInline item)) items)
  Links links ->
    R.ul {} (map renderContentLink links)
  Images images ->
    R.div {} (map renderContentImage images)

renderContentLink :: ContentLink -> JSX
renderContentLink link = R.li {}
  [ R.a
      { href: link.href
      }
      [ R.text link.label ]
  ]

renderContentInline :: ContentInline -> JSX
renderContentInline = case _ of
  InlineText text -> R.text text
  InlineLink link ->
    R.a { href: link.href } [ R.text link.label ]

renderContentImage :: ContentImage -> JSX
renderContentImage image = R.p {}
  [ R.img
      { className: "mx-auto mb-8"
      , src: image.src
      , alt: image.alt
      }
  ]
