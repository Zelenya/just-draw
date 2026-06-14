module App.Route
  ( Route(..)
  , parsePath
  ) where

import Prelude hiding ((/))

import App.Path (BasePath, RoutePath, pathForParser)
import Data.Either (either)
import Data.Generic.Rep (class Generic)
import Routing.Duplex (RouteDuplex', end, parse, root, segment, string)
import Routing.Duplex.Generic (noArgs, sum)
import Routing.Duplex.Generic.Syntax ((/))

data Route
  = Home
  | Exercise String
  | Tag String
  | NotFound

derive instance Generic Route _
derive instance eqRoute :: Eq Route

routes :: RouteDuplex' Route
routes =
  root $ end $ sum
    { "Home": noArgs
    , "Exercise": string segment
    , "Tag": "tag" / string segment
    , "NotFound": "404" / noArgs
    }

parsePath :: BasePath -> RoutePath -> Route
parsePath basePath pathname =
  either (const NotFound) identity (parse routes (pathForParser basePath pathname))
