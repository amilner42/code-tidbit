module Models.Tidbit exposing (..)

import Date as Date
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Snipbit as SnipbitModel
import Models.Bigbit as BigbitModel
import Models.Route as Route
import Models.TidbitPointer as TidbitPointer


{-| All the different tidbit types.
-}
type Tidbit
    = Snipbit SnipbitModel.Snipbit
    | Bigbit BigbitModel.Bigbit


{-| Gets the name of a tidbit.
-}
getName : Tidbit -> String
getName tidbit =
    case tidbit of
        Snipbit { name } ->
            name

        Bigbit { name } ->
            name


{-| Gets the ID of a tidbit.
-}
getID : Tidbit -> String
getID tidbit =
    case tidbit of
        Snipbit { id } ->
            id

        Bigbit { id } ->
            id


{-| Gets the date a tidbit was last modified.
-}
getLastModified : Tidbit -> Date.Date
getLastModified tidbit =
    case tidbit of
        Snipbit { lastModified } ->
            lastModified

        Bigbit { lastModified } ->
            lastModified


{-| Gets the route-base for viewing the tidbit, still requires the ID to become
a full `Route`.
-}
getTidbitRoute : Maybe String -> Tidbit -> Route.Route
getTidbitRoute fromStoryID tidbit =
    case tidbit of
        Snipbit { id } ->
            Route.HomeComponentViewSnipbitIntroduction fromStoryID id

        Bigbit { id } ->
            Route.HomeComponentViewBigbitIntroduction fromStoryID id Nothing


{-| Gets the name for tidbit type.
-}
getTypeName : Tidbit -> String
getTypeName tidbit =
    case tidbit of
        Snipbit _ ->
            "Snipbit"

        Bigbit _ ->
            "Bigbit"


{-| Converts a tidbit to compressed-pointer form.
-}
compressTidbit : Tidbit -> TidbitPointer.TidbitPointer
compressTidbit tidbit =
    case tidbit of
        Snipbit { id } ->
            { tidbitType = TidbitPointer.Snipbit
            , targetID = id
            }

        Bigbit { id } ->
            { tidbitType = TidbitPointer.Bigbit
            , targetID = id
            }


{-| Tidbit encoder.
-}
encoder : Tidbit -> Encode.Value
encoder tidbit =
    case tidbit of
        Snipbit snipbit ->
            SnipbitModel.snipbitEncoder snipbit

        Bigbit bigbit ->
            BigbitModel.bigbitEncoder bigbit


{-| Tidbit decodoer.
-}
decoder : Decode.Decoder Tidbit
decoder =
    let
        decodeSnipbit : Decode.Decoder Tidbit
        decodeSnipbit =
            Decode.map Snipbit SnipbitModel.snipbitDecoder

        decodeBigbit : Decode.Decoder Tidbit
        decodeBigbit =
            Decode.map Bigbit BigbitModel.bigbitDecoder
    in
        Decode.oneOf [ decodeSnipbit, decodeBigbit ]
