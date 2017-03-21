module Models.Story exposing (..)

import Date
import Models.Tidbit as Tidbit
import Models.TidbitPointer as TidbitPointer
import Models.Route as Route


{-| The story model.
-}
type alias Story =
    { id : String
    , author : String
    , name : String
    , description : String
    , tags : List String
    , tidbitPointers : List TidbitPointer.TidbitPointer
    , createdAt : Date.Date
    , lastModified : Date.Date
    , userHasCompleted : Maybe (List Bool)
    }


{-| The expanded-story model.
-}
type alias ExpandedStory =
    { id : String
    , author : String
    , name : String
    , description : String
    , tags : List String
    , tidbits : List Tidbit.Tidbit
    , createdAt : Date.Date
    , lastModified : Date.Date
    , userHasCompleted : Maybe (List Bool)
    }


{-| A new story being created, does not yet contain any db-added fields.

This data structure can also represent the information for editing a story.
-}
type alias NewStory =
    { name : String
    , description : String
    , tags : List String
    }


{-| An empty new story.
-}
defaultNewStory : NewStory
defaultNewStory =
    { name = ""
    , description = ""
    , tags = []
    }


{-| A completely blank story.

Meaningless stub-dates are used for the dates.
-}
blankStory : Story
blankStory =
    { id = ""
    , author = ""
    , name = ""
    , description = ""
    , tags = []
    , tidbitPointers = []
    , createdAt = Date.fromTime 0
    , lastModified = Date.fromTime 0
    , userHasCompleted = Nothing
    }


{-| Given the ID of a tidbit and a list of tidbits, gets the route for the
tidbit after the current one if one exists after.
-}
getNextTidbitRoute : String -> String -> List Tidbit.Tidbit -> Maybe Route.Route
getNextTidbitRoute currentTidbitID currentStoryID storyTidbits =
    case storyTidbits of
        [] ->
            Nothing

        [ a ] ->
            Nothing

        head :: next :: rest ->
            if Tidbit.getID head == currentTidbitID then
                Just <| Tidbit.getTidbitRoute (Just currentStoryID) next
            else
                getNextTidbitRoute currentTidbitID currentStoryID (next :: rest)


{-| Given the ID of a tidbit and a list of tidbits, gets the route for the
tidbit before the current one if one exists before.
-}
getPreviousTidbitRoute : String -> String -> List Tidbit.Tidbit -> Maybe Route.Route
getPreviousTidbitRoute currentTidbitID currentStoryID storyTidbits =
    getNextTidbitRoute currentTidbitID currentStoryID (List.reverse storyTidbits)
