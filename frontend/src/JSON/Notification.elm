module JSON.Notification exposing (..)

import DefaultServices.Util as Util
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Models.Notification exposing (..)


{-| `Notification` encoder.
-}
encoder : Notification -> Encode.Value
encoder notification =
    let
        actionLinkEncoder =
            Util.encodePair Encode.string Encode.string
    in
    Encode.object
        [ ( "id", Encode.string notification.id )
        , ( "userID", Encode.string notification.userID )
        , ( "type", Encode.int notification.kind )
        , ( "message", Encode.string notification.message )
        , ( "actionLink", actionLinkEncoder notification.actionLink )
        , ( "read", Encode.bool notification.read )
        , ( "createdAt", Util.dateEncoder notification.createdAt )
        , ( "hash", Encode.string notification.hash )
        ]


{-| `Notification` decoder.
-}
decoder : Decode.Decoder Notification
decoder =
    let
        decodeActionLink =
            Util.decodePair Decode.string Decode.string
    in
    decode Notification
        |> required "id" Decode.string
        |> required "userID" Decode.string
        |> required "type" Decode.int
        |> required "message" Decode.string
        |> required "actionLink" decodeActionLink
        |> required "read" Decode.bool
        |> required "createdAt" Util.dateDecoder
        |> required "hash" Decode.string
