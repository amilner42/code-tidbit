module Components.Home.Model exposing (..)

import DefaultServices.Util as Util
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.Snipbit as Snipbit


{-| Home Component Model.
-}
type alias Model =
    { logOutError : Maybe ApiError.ApiError
    , showInfoFor : Maybe TidbitType
    , creatingSnipbitData : Snipbit.SnipbitCreateData
    }


{-| Basic union to keep track of tidbit types.
-}
type TidbitType
    = SnipBit
    | BigBit


{-| TidbitType `cacheEncoder`.
-}
tidbitTypeCacheEncoder : TidbitType -> Encode.Value
tidbitTypeCacheEncoder tidbitType =
    Encode.string <| toString tidbitType


{-| TidbitType `cacheDecoder`.
-}
tidbitTypeCacheDecoder : Decode.Decoder TidbitType
tidbitTypeCacheDecoder =
    let
        fromStringDecoder encodedTidbitType =
            case encodedTidbitType of
                "SnipBit" ->
                    Decode.succeed SnipBit

                "BigBit" ->
                    Decode.succeed BigBit

                _ ->
                    Decode.fail <| encodedTidbitType ++ " is not a valid encoded tidbit type."
    in
        Decode.andThen fromStringDecoder Decode.string


{-| Home Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "logOutError", Encode.null )
        , ( "showInfoFor", Util.justValueOrNull tidbitTypeCacheEncoder model.showInfoFor )
        , ( "creatingSnipbitData"
          , Snipbit.createDataCacheEncoder model.creatingSnipbitData
          )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    Decode.map3 Model
        (field "logOutError" (Decode.null Nothing))
        (field "showInfoFor" (Decode.maybe tidbitTypeCacheDecoder))
        (field "creatingSnipbitData" (Snipbit.createDataCacheDecoder))
