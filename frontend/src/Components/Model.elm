module Components.Model exposing (..)

import Components.Home.Model as HomeModel
import Components.Welcome.Model as WelcomeModel
import DefaultServices.Util exposing (justValueOrNull)
import Elements.Editor as Editor
import Json.Encode as Encode
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Models.Route as Route
import Models.Story as Story
import Models.User as User
import Models.Tidbit as Tidbit
import Keyboard.Extra as KK


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
    , languages : List ( Editor.Language, String )
    , keysDown : KK.Model
    , userStories : Maybe (List Story.Story)
    , userTidbits : Maybe (List Tidbit.Tidbit)
    }


{-| A wrapper around KK.update to handle extra logic.

Extra Logic: When someone clicks shift-tab, they could let go of the tab but
keep their hand on the shift and click the tab again to "double-shift-tab" to
allow this behaviour, every shift tab we reset it as if it was the first
shift-tab clicked.
-}
kkUpdateWrapper : KK.Msg -> KK.Model -> KK.Model
kkUpdateWrapper keyMsg keysDown =
    let
        newKeysDown =
            KK.update keyMsg keysDown
    in
        case newKeysDown of
            [ Just key1, Nothing, Just key2 ] ->
                if
                    ((KK.fromCode key1) == KK.Tab)
                        && ((KK.fromCode key2) == KK.Shift)
                then
                    [ Just key1, Just key2 ]
                else
                    newKeysDown

            _ ->
                newKeysDown


{-| Updates `keysDown`.
-}
updateKeysDown : KK.Model -> Model -> Model
updateKeysDown newKeysDown model =
    let
        shared =
            model.shared
    in
        { model
            | shared =
                { shared
                    | keysDown = newKeysDown
                }
        }


{-| Updates 'keysDown' with the given list of `Key`s.
-}
updateKeysDownWithKeys : List KK.Key -> Model -> Model
updateKeysDownWithKeys newKeys =
    updateKeysDown (List.map (Just << KK.toCode) newKeys)


{-| Base Component `cacheDecoder`.
-}
cacheDecoder : Decode.Decoder Model
cacheDecoder =
    decode Model
        |> required "shared" sharedCacheDecoder
        |> required "homeComponent" (HomeModel.cacheDecoder)
        |> required "welcomeComponent" (WelcomeModel.cacheDecoder)


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
    decode Shared
        |> required "user" (Decode.maybe (User.cacheDecoder))
        |> required "route" Route.cacheDecoder
        |> required "languages" (Decode.succeed Editor.humanReadableListOfLanguages)
        |> required "keysDown" (Decode.succeed KK.init)
        |> required "userStories" (Decode.maybe <| Decode.list Story.storyDecoder)
        |> required "userTidbits" (Decode.maybe <| Decode.list Tidbit.decoder)


{-| Shared `cacheEncoder`.
-}
sharedCacheEncoder : Shared -> Encode.Value
sharedCacheEncoder shared =
    Encode.object
        [ ( "user", justValueOrNull User.cacheEncoder shared.user )
        , ( "route", Route.cacheEncoder shared.route )
        , ( "languages", Encode.null )
        , ( "keysDown", Encode.null )
        , ( "userStories", justValueOrNull (Encode.list << List.map Story.storyEncoder) shared.userStories )
        , ( "userTidbits", justValueOrNull (Encode.list << List.map Tidbit.encoder) shared.userTidbits )
        ]
