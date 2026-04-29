module App.Path
  ( BasePath(..)
  , RoutePath(..)
  , basePathFromString
  , exercisePath
  , nonEmptyRoutePath
  , notFoundPath
  , pathForParser
  , rootPath
  , routePathFromString
  , tagPath
  , trimRoutePath
  , withBasePath
  ) where

import Prelude

import Data.Maybe (Maybe(..), fromMaybe)
import Data.Newtype (class Newtype)
import Data.String as String
import Data.String.Pattern (Pattern(..))

newtype BasePath = BasePath String
newtype RoutePath = RoutePath String

derive instance newtypeBasePath :: Newtype BasePath _
derive instance newtypeRoutePath :: Newtype RoutePath _
derive newtype instance eqRoutePath :: Eq RoutePath

basePathFromString :: String -> BasePath
basePathFromString basePath = BasePath $
  case trimSlashes basePath of
    "" -> "/"
    trimmed -> "/" <> trimmed

rootPath :: RoutePath
rootPath = RoutePath "/"

notFoundPath :: RoutePath
notFoundPath = RoutePath "/404/"

exercisePath :: String -> RoutePath
exercisePath slugSegment = routePathFromString slugSegment

tagPath :: String -> RoutePath
tagPath tagName = routePathFromString ("tag/" <> tagName)

nonEmptyRoutePath :: String -> Maybe RoutePath
nonEmptyRoutePath value =
  case trimSlashes value of
    "" -> Nothing
    _ -> Just (routePathFromString value)

routePathFromString :: String -> RoutePath
routePathFromString value = RoutePath (normalizeHrefPath value)
  where
  normalizeHrefPath routePath =
    case trimSlashes routePath of
      "" -> "/"
      trimmed -> "/" <> trimmed <> "/"

withBasePath :: BasePath -> RoutePath -> String
withBasePath (BasePath basePath) (RoutePath routePath) =
  case basePath, routePath of
    "/", normalizedRoute -> normalizedRoute
    normalizedBase, "/" -> normalizedBase <> "/"
    normalizedBase, normalizedRoute -> normalizedBase <> normalizedRoute

pathForParser :: BasePath -> RoutePath -> String
pathForParser (BasePath normalizedBase) (RoutePath pathname) =
  if normalizedBase == "/" then
    absolutePath
  else if absolutePath == normalizedBase then
    "/"
  else case String.stripPrefix (Pattern (normalizedBase <> "/")) absolutePath of
    Just routePath -> "/" <> routePath
    Nothing -> absolutePath
  where
  absolutePath = case trimSlashes pathname of
    "" -> "/"
    trimmed -> "/" <> trimmed

trimRoutePath :: RoutePath -> String
trimRoutePath (RoutePath routePath) =
  fromMaybe withoutPrefix (String.stripSuffix (Pattern "/") withoutPrefix)
  where
  withoutPrefix =
    fromMaybe routePath (String.stripPrefix (Pattern "/") routePath)

trimSlashes :: String -> String
trimSlashes = trimTrailingSlash <<< trimLeadingSlash
  where
  trimLeadingSlash value =
    case String.stripPrefix (Pattern "/") value of
      Just rest -> trimLeadingSlash rest
      Nothing -> value

  trimTrailingSlash value =
    case String.stripSuffix (Pattern "/") value of
      Just rest -> trimTrailingSlash rest
      Nothing -> value
