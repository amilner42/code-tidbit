module Pages.View exposing (view)

import Pages.Home.Model as HomeModel
import Pages.Home.View as HomeView
import Pages.Messages exposing (Msg(..))
import Pages.Model exposing (Model, Shared)
import Pages.Welcome.Model as WelcomeModel
import Pages.Welcome.View as WelcomeView
import Html exposing (div)
import Html.Attributes exposing (class)
import Models.Route as Route


{-| Loads the correct view depending on the route we are on.

NOTE: The way we structure the routing we don't need to do ANY checking here
to see if the route being loaded is correct (eg. maybe their loading a route
that needs auth but they're not logged in) because that logic is already
handled in `handleLocationChange`. At the point this function is called, the
user has already changed their route, we've already approved that the route
change is good and updated the model, and now we just need to render it.
-}
viewForRoute : Model -> Html.Html Msg
viewForRoute model =
    let
        renderedWelcomeView =
            welcomeView model.welcomeComponent model.shared

        renderedHomeView =
            homeView model.homeComponent model.shared
    in
        case model.shared.route of
            Route.RegisterPage ->
                renderedWelcomeView

            Route.LoginPage ->
                renderedWelcomeView

            Route.BrowsePage ->
                renderedHomeView

            Route.ViewSnipbitIntroductionPage _ _ ->
                renderedHomeView

            Route.ViewSnipbitConclusionPage _ _ ->
                renderedHomeView

            Route.ViewSnipbitFramePage _ _ _ ->
                renderedHomeView

            Route.ViewBigbitIntroductionPage _ _ _ ->
                renderedHomeView

            Route.ViewBigbitFramePage _ _ _ _ ->
                renderedHomeView

            Route.ViewBigbitConclusionPage _ _ _ ->
                renderedHomeView

            Route.ViewStoryPage _ ->
                renderedHomeView

            Route.CreatePage ->
                renderedHomeView

            Route.CreateSnipbitNamePage ->
                renderedHomeView

            Route.CreateSnipbitDescriptionPage ->
                renderedHomeView

            Route.CreateSnipbitLanguagePage ->
                renderedHomeView

            Route.CreateSnipbitTagsPage ->
                renderedHomeView

            Route.CreateSnipbitCodeIntroductionPage ->
                renderedHomeView

            Route.CreateSnipbitCodeFramePage _ ->
                renderedHomeView

            Route.CreateSnipbitCodeConclusionPage ->
                renderedHomeView

            Route.CreateBigbitNamePage ->
                renderedHomeView

            Route.CreateBigbitDescriptionPage ->
                renderedHomeView

            Route.CreateBigbitTagsPage ->
                renderedHomeView

            Route.CreateBigbitCodeIntroductionPage _ ->
                renderedHomeView

            Route.CreateBigbitCodeFramePage _ _ ->
                renderedHomeView

            Route.CreateBigbitCodeConclusionPage _ ->
                renderedHomeView

            Route.CreateStoryNamePage _ ->
                renderedHomeView

            Route.CreateStoryDescriptionPage _ ->
                renderedHomeView

            Route.CreateStoryTagsPage _ ->
                renderedHomeView

            Route.DevelopStoryPage _ ->
                renderedHomeView

            Route.ProfilePage ->
                renderedHomeView


{-| The welcome view.
-}
welcomeView : WelcomeModel.Model -> Shared -> Html.Html Msg
welcomeView welcomeModel shared =
    Html.map WelcomeMessage (WelcomeView.view welcomeModel shared)


{-| The home view.
-}
homeView : HomeModel.Model -> Shared -> Html.Html Msg
homeView homeModel shared =
    Html.map HomeMessage (HomeView.view homeModel shared)


{-| Base component view.
-}
view : Model -> Html.Html Msg
view model =
    div
        [ class "base-component-wrapper" ]
        [ div
            [ class "base-component" ]
            [ viewForRoute model ]
          -- Used for smooth scrolling to the bottom.
        , div
            [ class "invisible-bottom" ]
            []
        ]
