module Main where

import Prelude

import App (AppEnv, mkApp)
import Data.Maybe (Maybe(..))
import Effect.Exception (throw)
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import React.Basic.DOM.Client (hydrateRoot)
import Web.DOM.NonElementParentNode (getElementById)
import Web.HTML (window)
import Web.HTML.HTMLDocument (toNonElementParentNode)
import Web.HTML.Window (document)

main :: EffectFn1 AppEnv Unit
main = mkEffectFn1 \env -> do
  doc <- document =<< window
  container <- getElementById "app" (toNonElementParentNode doc)

  case container of
    Nothing -> throw "Could not find the app container"
    Just node -> do
      app <- mkApp
      _ <- hydrateRoot node (app env)
      pure unit
