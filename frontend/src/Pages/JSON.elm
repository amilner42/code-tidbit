module Pages.JSON exposing (..)

import DefaultServices.Util exposing (justValueOrNull)
import Elements.Editor as Editor
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as Encode
import JSON.Route
import JSON.Story
import JSON.Tidbit
import JSON.User
import Keyboard.Extra as KK
import Pages.Create.JSON as CreateJSON
import Pages.CreateBigbit.JSON as CreateBigbitJSON
import Pages.CreateBigbit.Model as HomeModel
import Pages.CreateSnipbit.JSON as CreateSnipbitJSON
import Pages.DevelopStory.JSON as DevelopStoryJSON
import Pages.Model exposing (..)
import Pages.NewStory.JSON as NewStoryJSON
import Pages.Profile.JSON as ProfileJSON
import Pages.ViewBigbit.JSON as ViewBigbitJSON
import Pages.ViewSnipbit.JSON as ViewSnipbitJSON
import Pages.Welcome.JSON as WelcomeJSON


{-| `Base` encoder.
-}
encoder : Model -> Encode.Value
encoder model =
    Encode.object
        [ ( "shared", sharedEncoder model.shared )
        , ( "welcomePage", WelcomeJSON.encoder model.welcomePage )
        , ( "viewSnipbitPage", ViewSnipbitJSON.encoder model.viewSnipbitPage )
        , ( "viewBigbitPage", ViewBigbitJSON.encoder model.viewBigbitPage )
        , ( "profilePage", ProfileJSON.encoder model.profilePage )
        , ( "newStoryPage", NewStoryJSON.encoder model.newStoryPage )
        , ( "createPage", CreateJSON.encoder model.createPage )
        , ( "developStoryPage", DevelopStoryJSON.encoder model.developStoryPage )
        , ( "createSnipbitPage", CreateSnipbitJSON.encoder model.createSnipbitPage )
        , ( "createBigbitPage", CreateBigbitJSON.encoder model.createBigbitPage )
        ]


{-| `Base` decoder.
-}
decoder : Decode.Decoder Model
decoder =
    decode Model
        |> required "shared" sharedDecoder
        |> required "welcomePage" (WelcomeJSON.decoder)
        |> required "viewSnipbitPage" ViewSnipbitJSON.decoder
        |> required "viewBigbitPage" ViewBigbitJSON.decoder
        |> required "profilePage" ProfileJSON.decoder
        |> required "newStoryPage" NewStoryJSON.decoder
        |> required "createPage" CreateJSON.decoder
        |> required "developStoryPage" DevelopStoryJSON.decoder
        |> required "createSnipbitPage" CreateSnipbitJSON.decoder
        |> required "createBigbitPage" CreateBigbitJSON.decoder


{-| `Shared` encoder.
-}
sharedEncoder : Shared -> Encode.Value
sharedEncoder shared =
    Encode.object
        [ ( "user", justValueOrNull JSON.User.safeEncoder shared.user )
        , ( "route", JSON.Route.encoder shared.route )
        , ( "languages", Encode.null )
        , ( "keysDown", Encode.null )
        , ( "userStories", justValueOrNull (Encode.list << List.map JSON.Story.encoder) shared.userStories )
        , ( "userTidbits", justValueOrNull (Encode.list << List.map JSON.Tidbit.encoder) shared.userTidbits )
        , ( "viewingStory", justValueOrNull JSON.Story.expandedStoryEncoder shared.viewingStory )
        ]


{-| `Shared` decoder.
-}
sharedDecoder : Decode.Decoder Shared
sharedDecoder =
    decode Shared
        |> required "user" (Decode.maybe JSON.User.decoder)
        |> required "route" JSON.Route.decoder
        |> required "languages" (Decode.succeed Editor.humanReadableListOfLanguages)
        |> required "keysDown" (Decode.succeed KK.init)
        |> required "userStories" (Decode.maybe <| Decode.list JSON.Story.decoder)
        |> required "userTidbits" (Decode.maybe <| Decode.list JSON.Tidbit.decoder)
        |> required "viewingStory" (Decode.maybe <| JSON.Story.expandedStoryDecoder)
