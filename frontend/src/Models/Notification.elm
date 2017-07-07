module Models.Notification exposing (..)

import Date
import ProjectTypeAliases exposing (..)


{-| A notification as seen in the database.
-}
type alias Notification =
    { id : NotificationID
    , userID : UserID
    , kind : Int -- field name `type` on the backend
    , message : String
    , actionLink : ( LinkName, Link )
    , read : Bool
    , createdAt : Date.Date
    , hash : String
    }
