module Components.Home.Model exposing (Model, cacheEncoder, cacheDecoder)

import DefaultServices.Util as Util
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.TidbitType as TidbitType
import Models.BasicTidbit as BasicTidbit


{-| Home Component Model.
-}
type alias Model =
    { logOutError : Maybe ApiError.ApiError
    , creatingTidbitType : Maybe TidbitType.TidbitType
    , creatingBasicTidbitData : BasicTidbit.BasicTidbitCreateData
    }


{-| Home Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "logOutError", Encode.null )
        , ( "creatingTidbitType"
          , Util.justValueOrNull
                TidbitType.cacheEncoder
                model.creatingTidbitType
          )
        , ( "creatingBasicTidbitData"
          , BasicTidbit.createDataCacheEncoder model.creatingBasicTidbitData
          )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    Decode.map3 Model
        (field "logOutError" (Decode.null Nothing))
        (field "creatingTidbitType" (Decode.maybe TidbitType.cacheDecoder))
        (field "creatingBasicTidbitData" (BasicTidbit.createDataCacheDecoder))
