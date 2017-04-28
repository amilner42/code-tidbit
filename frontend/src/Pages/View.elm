module Pages.View exposing (view)

import DefaultServices.Util as Util
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, src, classList)
import Html.Events exposing (onClick)
import Models.ApiError as ApiError
import Models.Bigbit as Bigbit
import Models.Route as Route
import Pages.Browse.Model as BrowseModel
import Pages.Browse.View as BrowseView
import Pages.Create.Model as CreateModel
import Pages.Create.View as CreateView
import Pages.CreateBigbit.Model as CreateBigbitModel
import Pages.CreateBigbit.Model as HomeModel
import Pages.CreateBigbit.View as CreateBigbitView
import Pages.CreateBigbit.View as HomeView
import Pages.CreateSnipbit.Model as CreateSnipbitModel
import Pages.CreateSnipbit.View as CreateSnipbitView
import Pages.DevelopStory.Model as DevelopStoryModel
import Pages.DevelopStory.View as DevelopStoryView
import Pages.Messages exposing (Msg(..))
import Pages.Model exposing (Model, Shared)
import Pages.NewStory.Model as NewStoryModel
import Pages.NewStory.View as NewStoryView
import Pages.Profile.Model as ProfileModel
import Pages.Profile.View as ProfileView
import Pages.ViewBigbit.Model as ViewBigbitModel
import Pages.ViewBigbit.View as ViewBigbitView
import Pages.ViewSnipbit.Model as ViewSnipbitModel
import Pages.ViewSnipbit.View as ViewSnipbitView
import Pages.ViewStory.Model as ViewStoryModel
import Pages.ViewStory.View as ViewStoryView
import Pages.Welcome.Model as WelcomeModel
import Pages.Welcome.View as WelcomeView


{-| `Base` view.

NOTE: This is the Html entry point to the entire application.
-}
view : Model -> Html.Html Msg
view model =
    div
        [ class "base-page-wrapper" ]
        [ div
            [ class "base-page" ]
            [ navbarIfOnRoute model
            , viewForRoute model
            ]

        -- The modal for displaying errors.
        , Util.maybeMapWithDefault errorModal Util.hiddenDiv model.shared.apiModalError

        -- Used for smooth scrolling to the bottom.
        , div [ class "invisible-bottom" ] []
        ]


{-| A basic modal for displaying the message in human readable format.
-}
errorModal : ApiError.ApiError -> Html Msg
errorModal apiError =
    div
        []
        [ -- The modal background.
          div
            [ class "modal-bg"
            , onClick CloseModal
            ]
            []

        -- The actual modal box.
        , div
            [ class "modal-box" ]
            [ div
                [ class "modal-title" ]
                [ text "An Error Occured" ]
            , div
                [ class "modal-message" ]
                [ text <| ApiError.humanReadable apiError ]
            ]
        ]


{-| Loads the correct view depending on the route we are on.

NOTE: The way we structure the routing we don't need to do ANY checking here to see if the route being loaded is correct
      (eg. maybe their loading a route that needs auth but they're not logged in) because that logic is already handled
      in `handleLocationChange`. At the point this function is called, the user has already changed their route, we've
      already approved that the route change is good and updated the model, and now we just need to render it.
-}
viewForRoute : Model -> Html.Html Msg
viewForRoute model =
    let
        welcomePage =
            welcomeView model.welcomePage model.shared

        viewSnipbitPage =
            viewSnipbitView model.viewSnipbitPage model.shared

        viewBigbitPage =
            viewBigbitView model.viewBigbitPage model.shared

        viewStoryPage =
            viewStoryView model.viewStoryPage model.shared

        profilePage =
            profileView model.profilePage model.shared

        newStoryPage =
            newStoryView model.newStoryPage model.shared

        createPage =
            createView model.createPage model.shared

        developStoryPage =
            developStoryView model.developStoryPage model.shared

        createSnipbitPage =
            createSnipbitView model.createSnipbitPage model.shared

        createBigbitPage =
            createBigbitView model.createBigbitPage model.shared

        browsePage =
            browseView model.browsePage model.shared
    in
        case model.shared.route of
            Route.RegisterPage ->
                welcomePage

            Route.LoginPage ->
                welcomePage

            Route.BrowsePage ->
                browsePage

            Route.ViewSnipbitIntroductionPage _ _ ->
                viewSnipbitPage

            Route.ViewSnipbitConclusionPage _ _ ->
                viewSnipbitPage

            Route.ViewSnipbitFramePage _ _ _ ->
                viewSnipbitPage

            Route.ViewBigbitIntroductionPage _ _ _ ->
                viewBigbitPage

            Route.ViewBigbitFramePage _ _ _ _ ->
                viewBigbitPage

            Route.ViewBigbitConclusionPage _ _ _ ->
                viewBigbitPage

            Route.ViewStoryPage _ ->
                viewStoryPage

            Route.CreatePage ->
                createPage

            Route.CreateSnipbitNamePage ->
                createSnipbitPage

            Route.CreateSnipbitDescriptionPage ->
                createSnipbitPage

            Route.CreateSnipbitLanguagePage ->
                createSnipbitPage

            Route.CreateSnipbitTagsPage ->
                createSnipbitPage

            Route.CreateSnipbitCodeIntroductionPage ->
                createSnipbitPage

            Route.CreateSnipbitCodeFramePage _ ->
                createSnipbitPage

            Route.CreateSnipbitCodeConclusionPage ->
                createSnipbitPage

            Route.CreateBigbitNamePage ->
                createBigbitPage

            Route.CreateBigbitDescriptionPage ->
                createBigbitPage

            Route.CreateBigbitTagsPage ->
                createBigbitPage

            Route.CreateBigbitCodeIntroductionPage _ ->
                createBigbitPage

            Route.CreateBigbitCodeFramePage _ _ ->
                createBigbitPage

            Route.CreateBigbitCodeConclusionPage _ ->
                createBigbitPage

            Route.CreateStoryNamePage _ ->
                newStoryPage

            Route.CreateStoryDescriptionPage _ ->
                newStoryPage

            Route.CreateStoryTagsPage _ ->
                newStoryPage

            Route.DevelopStoryPage _ ->
                developStoryPage

            Route.ProfilePage ->
                profilePage


{-| `Welcome` view.
-}
welcomeView : WelcomeModel.Model -> Shared -> Html.Html Msg
welcomeView welcomeModel shared =
    Html.map WelcomeMessage (WelcomeView.view welcomeModel shared)


{-| `ViewSnipbit` view.
-}
viewSnipbitView : ViewSnipbitModel.Model -> Shared -> Html.Html Msg
viewSnipbitView viewSnipbitModel shared =
    Html.map ViewSnipbitMessage <| ViewSnipbitView.view viewSnipbitModel shared


{-| `ViewBigbit` view.
-}
viewBigbitView : ViewBigbitModel.Model -> Shared -> Html.Html Msg
viewBigbitView viewBigbitModel shared =
    Html.map ViewBigbitMessage <| ViewBigbitView.view viewBigbitModel shared


{-| `ViewStory` view.
-}
viewStoryView : ViewStoryModel.Model -> Shared -> Html.Html Msg
viewStoryView viewStoryModel shared =
    Html.map ViewStoryMessage <| ViewStoryView.view viewStoryModel shared


{-| `Profile` view.
-}
profileView : ProfileModel.Model -> Shared -> Html.Html Msg
profileView profileModel shared =
    Html.map ProfileMessage <| ProfileView.view profileModel shared


{-| `NewStory` view.
-}
newStoryView : NewStoryModel.Model -> Shared -> Html.Html Msg
newStoryView newStoryModel shared =
    Html.map NewStoryMessage <| NewStoryView.view newStoryModel shared


{-| `Create` view.
-}
createView : CreateModel.Model -> Shared -> Html.Html Msg
createView createModel shared =
    Html.map CreateMessage <| CreateView.view createModel shared


{-| `DevelopStory` view.
-}
developStoryView : DevelopStoryModel.Model -> Shared -> Html.Html Msg
developStoryView developStoryModel shared =
    Html.map DevelopStoryMessage <| DevelopStoryView.view developStoryModel shared


{-| `CreateSnipbit` view.
-}
createSnipbitView : CreateSnipbitModel.Model -> Shared -> Html.Html Msg
createSnipbitView createSnipbitModel shared =
    Html.map CreateSnipbitMessage <| CreateSnipbitView.view createSnipbitModel shared


{-| `CreateBigbit` view.
-}
createBigbitView : CreateBigbitModel.Model -> Shared -> Html.Html Msg
createBigbitView createBigbitModel shared =
    Html.map CreateBigbitMessage (CreateBigbitView.view createBigbitModel shared)


{-| `Browse` view.
-}
browseView : BrowseModel.Model -> Shared -> Html.Html Msg
browseView browseModel shared =
    Html.map BrowseMessage (BrowseView.view browseModel shared)


{-| Displays the navbar if the route is not on the welcome page.
-}
navbarIfOnRoute : Model -> Html Msg
navbarIfOnRoute model =
    case model.shared.route of
        Route.LoginPage ->
            Util.hiddenDiv

        Route.RegisterPage ->
            Util.hiddenDiv

        _ ->
            navbar model


{-| Horizontal navbar to go above the views.
-}
navbar : Model -> Html Msg
navbar model =
    let
        shared =
            model.shared

        browseViewSelected =
            case shared.route of
                Route.BrowsePage ->
                    True

                Route.ViewSnipbitIntroductionPage _ _ ->
                    True

                Route.ViewSnipbitFramePage _ _ _ ->
                    True

                Route.ViewSnipbitConclusionPage _ _ ->
                    True

                Route.ViewBigbitIntroductionPage _ _ _ ->
                    True

                Route.ViewBigbitFramePage _ _ _ _ ->
                    True

                Route.ViewBigbitConclusionPage _ _ _ ->
                    True

                Route.ViewStoryPage _ ->
                    True

                _ ->
                    False

        profileViewSelected =
            shared.route == Route.ProfilePage

        createViewSelected =
            case shared.route of
                Route.CreateSnipbitCodeFramePage _ ->
                    True

                Route.CreateBigbitCodeFramePage _ _ ->
                    True

                Route.CreateBigbitCodeIntroductionPage _ ->
                    True

                Route.CreateBigbitCodeConclusionPage _ ->
                    True

                Route.DevelopStoryPage _ ->
                    True

                Route.CreateStoryNamePage _ ->
                    True

                Route.CreateStoryDescriptionPage _ ->
                    True

                Route.CreateStoryTagsPage _ ->
                    True

                _ ->
                    (List.member
                        shared.route
                        [ Route.CreatePage
                        , Route.CreateSnipbitNamePage
                        , Route.CreateSnipbitDescriptionPage
                        , Route.CreateSnipbitLanguagePage
                        , Route.CreateSnipbitTagsPage
                        , Route.CreateSnipbitCodeIntroductionPage
                        , Route.CreateSnipbitCodeConclusionPage
                        , Route.CreateBigbitNamePage
                        , Route.CreateBigbitDescriptionPage
                        , Route.CreateBigbitTagsPage
                        ]
                    )
    in
        div
            [ classList
                [ ( "nav", True )
                , ( "nav-wide-2", isWideNav2 model )
                , ( "nav-wide-3", isWideNav3 model )
                ]
            ]
            [ img
                [ class "logo"
                , src "assets/ct-logo-small.png"
                ]
                []
            , div
                [ classList
                    [ ( "nav-btn left code-tidbit", True )
                    , ( "hidden", Util.isNotNothing shared.user )
                    ]
                , onClick <| GoTo Route.BrowsePage
                ]
                [ text "Code Tidbit" ]
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "hidden", Util.isNothing shared.user )
                    , ( "selected", browseViewSelected )
                    ]
                , onClick <| GoTo Route.BrowsePage
                ]
                [ text "Browse" ]
            , div
                [ classList
                    [ ( "nav-btn left", True )
                    , ( "hidden", Util.isNothing shared.user )
                    , ( "selected", createViewSelected )
                    ]
                , onClick <| GoTo Route.CreatePage
                ]
                [ text "Create" ]
            , div
                [ classList
                    [ ( "nav-btn right", True )
                    , ( "hidden", Util.isNothing shared.user )
                    , ( "selected", profileViewSelected )
                    ]
                , onClick <| GoTo Route.ProfilePage
                ]
                [ text "Profile" ]
            , div
                [ classList
                    [ ( "nav-btn sign-up right", True )
                    , ( "hidden", Util.isNotNothing shared.user )
                    ]
                , onClick <| GoTo Route.RegisterPage
                ]
                [ text "Sign Up" ]
            , div
                [ classList
                    [ ( "nav-btn login right", True )
                    , ( "hidden", Util.isNotNothing shared.user )
                    ]
                , onClick <| GoTo Route.LoginPage
                ]
                [ text "Login" ]
            ]


{-| Returns true if the nav needs to be `$min-width-supported-2` wide.

Currently wide-mode-2 is required for viewing bigbits when the FS is expanded.
-}
isWideNav2 : Model -> Bool
isWideNav2 model =
    let
        viewBigbitFSOpen =
            ViewBigbitModel.isBigbitFSOpen model.viewBigbitPage.bigbit
    in
        case model.shared.route of
            Route.ViewBigbitIntroductionPage _ _ _ ->
                viewBigbitFSOpen

            Route.ViewBigbitFramePage _ _ _ _ ->
                viewBigbitFSOpen

            Route.ViewBigbitConclusionPage _ _ _ ->
                viewBigbitFSOpen

            _ ->
                False


{-| Returns true if the nav needs to be `$min-width-supported-3` wide.

Currently wide-mode-3 is required for creating bigbits when the fs is expanded.
-}
isWideNav3 : Model -> Bool
isWideNav3 model =
    let
        createBigbitFSOpen =
            Bigbit.isFSOpen model.createBigbitPage.fs
    in
        case model.shared.route of
            Route.CreateBigbitCodeIntroductionPage _ ->
                createBigbitFSOpen

            Route.CreateBigbitCodeFramePage _ _ ->
                createBigbitFSOpen

            Route.CreateBigbitCodeConclusionPage _ ->
                createBigbitFSOpen

            _ ->
                False
