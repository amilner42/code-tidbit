module Pages.View exposing (view)

import DefaultServices.Util as Util
import Html exposing (Html, div, img, text)
import Html.Attributes exposing (class, src, classList)
import Html.Events exposing (onClick)
import Models.Route as Route
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
            [ navbarIfOnRoute model.shared
            , viewForRoute model
            ]
          -- Used for smooth scrolling to the bottom.
        , div
            [ class "invisible-bottom" ]
            []
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
            viewStoryView model.shared

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
    in
        case model.shared.route of
            Route.RegisterPage ->
                welcomePage

            Route.LoginPage ->
                welcomePage

            Route.BrowsePage ->
                div [] []

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
viewStoryView : Shared -> Html.Html Msg
viewStoryView shared =
    Html.map ViewStoryMessage <| ViewStoryView.view shared


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


{-| Displays the navbar if the route is not on the welcome page.
-}
navbarIfOnRoute : Shared -> Html Msg
navbarIfOnRoute shared =
    case shared.route of
        Route.LoginPage ->
            Util.hiddenDiv

        Route.RegisterPage ->
            Util.hiddenDiv

        _ ->
            navbar shared


{-| Horizontal navbar to go above the views.
-}
navbar : Shared -> Html Msg
navbar shared =
    let
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
        div [ class "nav" ]
            [ img
                [ class "logo"
                , src "assets/ct-logo.png"
                ]
                []
            , div
                [ classList
                    [ ( "nav-btn left code-tidbit", True )
                    , ( "hidden", Util.isNotNothing shared.user )
                    ]
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
