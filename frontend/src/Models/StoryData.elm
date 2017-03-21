module Models.StoryData exposing (..)

import Models.Story as Story
import Models.Tidbit as Tidbit


{-| The data for the create-story page.
-}
type alias StoryData =
    { currentStory : Maybe Story.ExpandedStory
    , tidbitsToAdd : List Tidbit.Tidbit
    }


{-| The default empty story data.
-}
defaultStoryData : StoryData
defaultStoryData =
    { currentStory = Nothing
    , tidbitsToAdd = []
    }


{-| Sets the `currentStory` to `expandedStory`.

NOTE: This also clears the `tidbitsToAdd` field.
-}
setCurrentStory : Story.ExpandedStory -> StoryData -> StoryData
setCurrentStory expandedStory storyData =
    { storyData
        | currentStory = Just expandedStory
        , tidbitsToAdd = []
    }


{-| Adds a tidbit to the `tidbitsToAdd` as long as it isn't already there.
-}
addTidbit : Tidbit.Tidbit -> StoryData -> StoryData
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
removeTidbit : Tidbit.Tidbit -> StoryData -> StoryData
removeTidbit tidbit storyData =
    { storyData
        | tidbitsToAdd =
            List.filter ((/=) tidbit) storyData.tidbitsToAdd
    }


{-| Returns a list of tidbits which are not members of `currentStories`.
-}
remainingTidbits : List Tidbit.Tidbit -> List Tidbit.Tidbit -> List Tidbit.Tidbit
remainingTidbits currentStories =
    List.filter
        (not << (flip List.member) currentStories)
