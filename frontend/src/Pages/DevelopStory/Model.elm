module Pages.DevelopStory.Model exposing (..)

import Models.Story as Story
import Models.Tidbit as Tidbit


{-| `DevelopStory` model.
-}
type alias Model =
    { story : Maybe Story.ExpandedStory
    , tidbitsToAdd : List Tidbit.Tidbit
    }


{-| Sets the `story` to `expandedStory`.
-}
setStory : Story.ExpandedStory -> Model -> Model
setStory expandedStory storyData =
    { storyData | story = Just expandedStory }


{-| Adds a tidbit to the `tidbitsToAdd` as long as it isn't already there.
-}
addTidbit : Tidbit.Tidbit -> Model -> Model
addTidbit tidbit storyData =
    { storyData
        | tidbitsToAdd =
            if List.member tidbit storyData.tidbitsToAdd then
                storyData.tidbitsToAdd
            else
                storyData.tidbitsToAdd ++ [ tidbit ]
    }


{-| Removes a tidbit from `tidbitsToAdd`.
-}
removeTidbit : Tidbit.Tidbit -> Model -> Model
removeTidbit tidbit storyData =
    { storyData | tidbitsToAdd = List.filter ((/=) tidbit) storyData.tidbitsToAdd }


{-| Returns a list of tidbits which are not members of `currentStories`.
-}
remainingTidbits : List Tidbit.Tidbit -> List Tidbit.Tidbit -> List Tidbit.Tidbit
remainingTidbits currentStories =
    List.filter (not << flip List.member currentStories)
