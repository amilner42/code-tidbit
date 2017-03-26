module Pages.NewStory.Init exposing (..)

import Models.Story exposing (blankStory, defaultNewStory)
import Pages.NewStory.Model exposing (..)


{-| `NewStory` init.
-}
init : Model
init =
    { newStory = defaultNewStory
    , editingStory = blankStory
    , tagInput = ""
    , editingStoryTagInput = ""
    }
