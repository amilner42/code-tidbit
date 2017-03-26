module Pages.DevelopStory.Init exposing (..)

import Pages.DevelopStory.Model exposing (..)


{-| `DevelopStory` init.
-}
init : Model
init =
    { story = Nothing
    , tidbitsToAdd = []
    }
