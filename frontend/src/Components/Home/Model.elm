module Components.Home.Model exposing (Model, cacheEncoder, cacheDecoder)

import DefaultServices.Util as Util
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Models.ApiError as ApiError
import Models.BasicTidbit as BasicTidbit


{-| Home Component Model.
-}
type alias Model =
    { logOutError : Maybe ApiError.ApiError
    , creatingBasicTidbitData : BasicTidbit.BasicTidbitCreateData
    }


{-| Home Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "logOutError", Encode.null )
        , ( "creatingBasicTidbitData"
          , BasicTidbit.createDataCacheEncoder model.creatingBasicTidbitData
          )
        ]


{-| Home Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    Decode.map2 Model
        (field "logOutError" (Decode.null Nothing))
        (field "creatingBasicTidbitData" (BasicTidbit.createDataCacheDecoder))
