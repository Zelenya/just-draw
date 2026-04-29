module Content
  ( ContentBlock(..)
  , ContentImage
  , ContentInline(..)
  , ContentLink
  , Exercise
  , SiteMetadata
  , Tag
  , exercises
  , site
  , tags
  ) where

import Prelude

import App.Path (RoutePath, exercisePath, tagPath)
import Data.Array as Array
import Data.Either (Either(..))
import Data.Maybe (Maybe, fromMaybe)
import Foreign (Foreign)
import Partial.Unsafe (unsafeCrashWith)
import Yoga.JSON as JSON

type SiteMetadata =
  { title :: String
  , description :: String
  }

type ContentLink =
  { label :: String
  , href :: String
  }

type ContentImage =
  { alt :: String
  , src :: String
  }

data ContentInline
  = InlineText String
  | InlineLink ContentLink

data ContentBlock
  = Heading Int String
  | Paragraph String
  | Quote String
  | List (Array (Array ContentInline))
  | Links (Array ContentLink)
  | Images (Array ContentImage)

type Exercise =
  { title :: String
  , slug :: RoutePath
  , slugSegment :: String
  , tags :: Array String
  , excerpt :: String
  , heroImage :: Maybe String
  , body :: Array ContentBlock
  }

type Tag =
  { name :: String
  , path :: RoutePath
  , description :: String
  , count :: Int
  }

type RawContent =
  { site :: SiteMetadata
  , tagDescriptions :: Array TagDescription
  , exercises :: Array RawExercise
  }

type RawExercise =
  { title :: String
  , slugSegment :: String
  , tags :: Array String
  , excerpt :: String
  , heroImage :: Maybe String
  , body :: Array RawContentBlock
  }

type TagDescription =
  { name :: String
  , description :: String
  }

type RawContentBlock =
  { kind :: String
  , level :: Int
  , text :: String
  , items :: Array (Array RawContentInline)
  , links :: Array ContentLink
  , images :: Array ContentImage
  }

type RawContentInline =
  { kind :: String
  , text :: String
  , label :: String
  , href :: String
  }

foreign import rawContent :: Foreign

content :: RawContent
content =
  case JSON.read rawContent of
    Right parsed -> parsed
    Left errors -> unsafeCrashWith ("Could not decode content/site.json: " <> show errors)

site :: SiteMetadata
site = content.site

exercises :: Array Exercise
exercises =
  Array.sortBy (comparing _.title) $
    content.exercises <#> \exercise ->
      { title: exercise.title
      , slug: exercisePath exercise.slugSegment
      , slugSegment: exercise.slugSegment
      , tags: exercise.tags
      , excerpt: exercise.excerpt
      , heroImage: exercise.heroImage
      , body: map toContentBlock exercise.body
      }

tags :: Array Tag
tags = tagNames <#> \name ->
  { name
  , path: tagPath name
  , description: tagDescription name
  , count: tagCount name
  }

tagNames :: Array String
tagNames = Array.sort $ Array.nub (content.exercises >>= _.tags)

tagCount :: String -> Int
tagCount name = Array.length $ Array.filter (\exercise -> Array.elem name exercise.tags) content.exercises

tagDescription :: String -> String
tagDescription name =
  fromMaybe ("Exercises tagged " <> name <> ".")
    ( _.description
        <$> Array.find (\description -> description.name == name) content.tagDescriptions
    )

toContentBlock :: RawContentBlock -> ContentBlock
toContentBlock block =
  case block.kind of
    "heading" -> Heading block.level block.text
    "paragraph" -> Paragraph block.text
    "quote" -> Quote block.text
    "list" -> List (map (map toContentInline) block.items)
    "links" -> Links block.links
    "images" -> Images block.images
    _ -> unsafeCrashWith ("Unknown content block kind: " <> block.kind)

toContentInline :: RawContentInline -> ContentInline
toContentInline inline =
  case inline.kind of
    "text" -> InlineText inline.text
    "link" -> InlineLink { label: inline.label, href: inline.href }
    _ -> unsafeCrashWith ("Unknown content inline kind: " <> inline.kind)
