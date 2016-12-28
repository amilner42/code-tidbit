module Components.Model exposing (Model, Shared, cacheDecoder, cacheEncoder)

import Components.Home.Model as HomeModel
import Components.Welcome.Model as WelcomeModel
import DefaultServices.Util exposing (justValueOrNull)
import Json.Decode as Decode exposing (field)
import Json.Encode as Encode
import Models.Route as Route
import Models.User as User


{-| Base Component Model.

The base component will have nested inside it the state of every individual
component as well as `shared`, which will be passed to all components so they
can share data.
-}
type alias Model =
    { shared : Shared
    , homeComponent : HomeModel.Model
    , welcomeComponent : WelcomeModel.Model
    }


{-| All data shared between components.
-}
type alias Shared =
    { user : Maybe (User.User)
    , route : Route.Route
    }


{-| Base Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    Decode.map3 Model
        (field "shared" sharedCacheDecoder)
        (field "homeComponent" (HomeModel.cacheDecoder))
        (field "welcomeComponent" (WelcomeModel.cacheDecoder))


{-| Base Component `cacheEncoder`.
-}
cacheEncoder : Model -> Encode.Value
cacheEncoder model =
    Encode.object
        [ ( "shared", sharedCacheEncoder model.shared )
        , ( "homeComponent", HomeModel.cacheEncoder model.homeComponent )
        , ( "welcomeComponent", WelcomeModel.cacheEncoder model.welcomeComponent )
        ]


{-| Shared `cacheDecoder`.
-}
sharedCacheDecoder : Decode.Decoder Shared
sharedCacheDecoder =
    Decode.map2 Shared
        (field "user" (Decode.maybe (User.cacheDecoder)))
        (field "route" Route.cacheDecoder)


{-| Shared `cacheEncoder`.
-}
sharedCacheEncoder : Shared -> Encode.Value
sharedCacheEncoder shared =
    Encode.object
        [ ( "user", justValueOrNull User.cacheEncoder shared.user )
        , ( "route", Route.cacheEncoder shared.route )
        ]
