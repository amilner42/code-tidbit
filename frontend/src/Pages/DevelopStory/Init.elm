module Pages.DevelopStory.Init exposing (..)

import Pages.DevelopStory.Model exposing (..)


{-| `DevelopStory` init.
-}
init : Model
init =
    { currentStory = Nothing
    , tidbitsToAdd = []
    }
