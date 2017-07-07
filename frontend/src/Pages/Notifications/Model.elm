module Pages.Notifications.Model exposing (..)

import Models.Notification exposing (Notification)


type alias Model =
    { notifications : Maybe ( Bool, List Notification )
    , pageNumber : Int
    }
