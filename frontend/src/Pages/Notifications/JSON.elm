module Pages.Notifications.JSON exposing (..)

import DefaultServices.Util as Util
import JSON.Notification
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Pages.Notifications.Model exposing (..)


{-| `Notifications` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    let
        encodeNotifications =
            Util.encodePair Encode.bool (Encode.list << List.map JSON.Notification.encoder)
    in
    Encode.object
        [ ( "notifications", Util.justValueOrNull encodeNotifications model.notifications )
        , ( "pageNumber", Encode.int model.pageNumber )
        ]


{-| `Notifications` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "notifications" (Decode.maybe <| Util.decodePair Decode.bool (Decode.list JSON.Notification.decoder))
        |> required "pageNumber" Decode.int
