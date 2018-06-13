module Pages.JSON exposing (..)

import DefaultServices.Util exposing (justValueOrNull)
import Dict
import Elements.Simple.Editor as Editor
import JSON.User
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (decode, hardcoded, optional, required)
import Json.Encode as Encode
import Keyboard.Extra as KK
import Material
import Models.Route as Route
import Pages.Browse.JSON as BrowseJSON
import Pages.Create.JSON as CreateJSON
import Pages.CreateBigbit.JSON as CreateBigbitJSON
import Pages.CreateSnipbit.JSON as CreateSnipbitJSON
import Pages.DevelopStory.JSON as DevelopStoryJSON
import Pages.Model exposing (..)
import Pages.NewStory.JSON as NewStoryJSON
import Pages.Notifications.Init as NotificationsInit
import Pages.Notifications.JSON as NotificationsJSON
import Pages.Profile.JSON as ProfileJSON
import Pages.ViewBigbit.JSON as ViewBigbitJSON
import Pages.ViewSnipbit.JSON as ViewSnipbitJSON
import Pages.ViewStory.Init as ViewStoryInit
import Pages.ViewStory.JSON as ViewStoryJSON
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
        , ( "browsePage", BrowseJSON.encoder model.browsePage )
        , ( "viewStoryPage", ViewStoryJSON.encoder model.viewStoryPage )
        , ( "notificationsPage", NotificationsJSON.encoder model.notificationsPage )
        ]


{-| `Base` decoder.
-}
decoder : Model -> Decode.Decoder Model
decoder model =
    decode Model
        |> required "shared" (sharedDecoder model.shared)
        |> required "welcomePage" WelcomeJSON.decoder
        |> required "viewSnipbitPage" ViewSnipbitJSON.decoder
        |> required "viewBigbitPage" ViewBigbitJSON.decoder
        |> required "profilePage" ProfileJSON.decoder
        |> required "newStoryPage" NewStoryJSON.decoder
        |> required "createPage" CreateJSON.decoder
        |> required "developStoryPage" DevelopStoryJSON.decoder
        |> required "createSnipbitPage" CreateSnipbitJSON.decoder
        |> required "createBigbitPage" CreateBigbitJSON.decoder
        |> required "browsePage" BrowseJSON.decoder
        -- Optional for backwards compatibility.
        |> optional "viewStoryPage" ViewStoryJSON.decoder ViewStoryInit.init
        |> optional "notificationsPage" NotificationsJSON.decoder NotificationsInit.init


{-| `Shared` encoder.
-}
sharedEncoder : Shared -> Encode.Value
sharedEncoder shared =
    Encode.object
        [ ( "user", justValueOrNull JSON.User.safeEncoder shared.user )
        , ( "route", Encode.null )
        , ( "languages", Encode.null )
        , ( "keysDown", Encode.null )
        , ( "userStories", Encode.null )
        , ( "userTidbits", Encode.null )
        , ( "viewingStory", Encode.null )
        , ( "flags", Encode.null )
        , ( "apiModalError", Encode.null )
        , ( "userNeedsAuthModal", Encode.null )
        , ( "apiRequestTracker", Encode.null )
        , ( "textFieldKeyTracker", Encode.null )
        , ( "mdlModel", Encode.null )
        , ( "logoutError", Encode.null )
        ]


{-| `Shared` decoder.
-}
sharedDecoder : Shared -> Decode.Decoder Shared
sharedDecoder shared =
    decode Shared
        |> required "user" (Decode.maybe JSON.User.decoder)
        |> hardcoded Route.BrowsePage
        |> required "languages" (Decode.succeed Editor.humanReadableListOfLanguages)
        |> required "keysDown" (Decode.succeed KK.init)
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> required "flags" (Decode.succeed shared.flags)
        |> hardcoded Nothing
        |> hardcoded Nothing
        |> hardcoded Dict.empty
        |> hardcoded Dict.empty
        |> hardcoded Material.model
        |> hardcoded Nothing
