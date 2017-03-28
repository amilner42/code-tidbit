module Models.Completed exposing (..)

import Models.TidbitPointer as TidbitPointer


{-| Marks a completed tidbit for a user. This matches the format on the backend.
-}
type alias Completed =
    { tidbitPointer : TidbitPointer.TidbitPointer
    , user : String
    }


{-| Convenience for storing on the frontend and keeping track of if something is completed. This is not replicated on
the backend.
-}
type alias IsCompleted =
    { tidbitPointer : TidbitPointer.TidbitPointer
    , complete : Bool
    }


{-| Makes a `Completed` from an `IsCompleted` and a userID.
-}
completedFromIsCompleted : IsCompleted -> String -> Completed
completedFromIsCompleted isCompleted userID =
    Completed isCompleted.tidbitPointer userID
