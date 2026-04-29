module Build.Static
  ( renderStaticFiles
  ) where

import Prelude

import App (AppEnv, mkApp)
import App.Path (BasePath(..), RoutePath, basePathFromString, notFoundPath, rootPath, trimRoutePath)
import Content (exercises, site, tags)
import Data.Array as Array
import Data.Newtype (unwrap)
import Data.String as String
import Data.String.Pattern (Pattern(..), Replacement(..))
import Effect.Uncurried (EffectFn1, mkEffectFn1)
import Partial.Unsafe (unsafeCrashWith)
import React.Basic (JSX)
import React.Basic.DOM.Server (renderToString)

type StaticPage =
  { routePath :: RoutePath
  , title :: String
  , description :: String
  }

type StaticFile =
  { outputPath :: String
  , html :: String
  }

renderStaticFiles :: EffectFn1 { basePath :: String } (Array StaticFile)
renderStaticFiles = mkEffectFn1 \{ basePath: rawBasePath } -> do
  app <- mkApp
  let basePath = basePathFromString rawBasePath
  let pages = validateRoutes staticPages
  pure $ renderRouteFiles app basePath pages <>
    [ { outputPath: "404.html"
      , html: renderDocument
          { basePath
          , bodyHtml: renderToString (app { basePath, pathname: notFoundPath })
          , description: notFoundPage.description
          , title: notFoundPage.title
          }
      }
    ]

staticPages :: Array StaticPage
staticPages =
  [ { routePath: rootPath
    , title: site.title
    , description: site.description
    }
  , notFoundPage
  ]
    <> exercisePages
    <> tagPages
  where
  exercisePages = exercises <#> \exercise ->
    { routePath: exercise.slug
    , title: exercise.title <> " | " <> site.title
    , description: exercise.excerpt
    }
  tagPages = tags <#> \tag ->
    { routePath: tag.path
    , title: tag.name <> " | " <> site.title
    , description: tag.description
    }

notFoundPage :: StaticPage
notFoundPage =
  { routePath: notFoundPath
  , title: "404 | " <> site.title
  , description: "That page is missing, but the drawing prompts are still here."
  }

renderRouteFiles
  :: (AppEnv -> JSX)
  -> BasePath
  -> Array StaticPage
  -> Array StaticFile
renderRouteFiles app basePath pages =
  pages
    <#> \page ->
      { outputPath: routeOutputPath page.routePath
      , html: renderDocument
          { basePath
          , bodyHtml: renderToString (app { basePath, pathname: page.routePath })
          , description: page.description
          , title: page.title
          }
      }
  where
  routeOutputPath :: RoutePath -> String
  routeOutputPath routePath =
    if routePath == rootPath then "index.html"
    else trimRoutePath routePath <> "/index.html"

renderDocument
  :: { basePath :: BasePath
     , bodyHtml :: String
     , description :: String
     , title :: String
     }
  -> String
renderDocument { basePath, bodyHtml, description, title } =
  "<!DOCTYPE html>\n"
    <> "<html lang=\"en\">\n"
    <> "  <head>\n"
    <> "    <meta charset=\"utf-8\" />\n"
    <> "    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n"
    <> "    <title>"
    <> escapeHtml title
    <> "</title>\n"
    <> "    <meta name=\"description\" content=\""
    <> escapeHtml description
    <> "\" />\n"
    <> "    <meta property=\"og:title\" content=\""
    <> escapeHtml title
    <> "\" />\n"
    <> "    <meta property=\"og:description\" content=\""
    <> escapeHtml description
    <> "\" />\n"
    <> "    <meta property=\"og:type\" content=\"website\" />\n"
    <> "    <meta name=\"twitter:card\" content=\"summary\" />\n"
    <> "    <link rel=\"icon\" href=\""
    <> assetHref basePath "/favicon.ico"
    <> "\" />\n"
    <> "    <link rel=\"stylesheet\" href=\""
    <> assetHref basePath "/style.css"
    <> "\" />\n"
    <> "  </head>\n"
    <> "  <body>\n"
    <> "    <div id=\"app\">"
    <> bodyHtml
    <> "</div>\n"
    <> "    <script type=\"module\" src=\""
    <> assetHref basePath "/index.js"
    <> "\"></script>\n"
    <> "  </body>\n"
    <> "</html>\n"

assetHref :: BasePath -> String -> String
assetHref (BasePath basePath) assetPath =
  (if basePath == "/" then "" else basePath) <> assetPath

escapeHtml :: String -> String
escapeHtml =
  String.replaceAll (Pattern "&") (Replacement "&amp;")
    >>> String.replaceAll (Pattern "<") (Replacement "&lt;")
    >>> String.replaceAll (Pattern ">") (Replacement "&gt;")
    >>> String.replaceAll (Pattern "\"") (Replacement "&quot;")
    >>> String.replaceAll (Pattern "'") (Replacement "&#39;")

validateRoutes :: Array StaticPage -> Array StaticPage
validateRoutes pages =
  if Array.length routePaths /= Array.length (Array.nub routePaths) then
    unsafeCrashWith "Static route paths are not unique."
  else
    pages
  where
  routePaths = map (unwrap <<< _.routePath) pages
