module ProjectTypeAliases exposing (..)

{- This module is intended to have all it's content imported [`import ProjectTypeAliases exposing (..)`] so be careful
   to use names that won't conflict with external names.
-}


type alias StoryID =
    String


type alias EditingStoryID =
    String


type alias SnipbitID =
    String


type alias BigbitID =
    String


type alias TidbitID =
    String


type alias QuestionID =
    String


type alias AnswerID =
    String


type alias ContentID =
    String


type alias FrameNumber =
    Int


type alias AnswerText =
    String


type alias QuestionText =
    String


type alias CommentID =
    String


type alias CommentText =
    String


type alias Email =
    String


type alias UserID =
    String


type alias NotificationID =
    String


type alias LinkName =
    String


type alias Link =
    String


type alias QueryParams =
    List ( String, Maybe String )


{-| For when you have a string where the value is irrelevant (currently helpful for query parameter).

NOTE: Only use this type if the value of the string should never be checked and does not matter.

-}
type alias MeaninglessString =
    String
