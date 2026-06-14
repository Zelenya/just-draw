module Components.Icon
  ( house
  , makeIcon
  ) where

import React.Basic (JSX, ReactComponent)
import React.Basic as React
import Unsafe.Coerce (unsafeCoerce)

type IconProps = (className :: String)

makeIcon :: ReactComponent { | IconProps } -> { | IconProps } -> JSX
makeIcon icon iconProps =
  React.element icon (unsafeCoerce iconProps :: { | IconProps })

foreign import house :: forall r. ReactComponent { | r }
