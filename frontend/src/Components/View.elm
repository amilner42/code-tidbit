module Components.View exposing (view)

import Components.Home.Model as HomeModel
import Components.Home.View as HomeView
import Components.Messages exposing (Msg(..))
import Components.Model exposing (Model, Shared)
import Components.Welcome.Model as WelcomeModel
import Components.Welcome.View as WelcomeView
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
            Route.WelcomeComponentRegister ->
                renderedWelcomeView

            Route.WelcomeComponentLogin ->
                renderedWelcomeView

            Route.HomeComponentBrowse ->
                renderedHomeView

            Route.HomeComponentCreate ->
                renderedHomeView

            Route.HomeComponentCreateBasicName ->
                renderedHomeView

            Route.HomeComponentCreateBasicDescription ->
                renderedHomeView

            Route.HomeComponentCreateBasicLanguage ->
                renderedHomeView

            Route.HomeComponentCreateBasicTags ->
                renderedHomeView

            Route.HomeComponentCreateBasicTidbit ->
                renderedHomeView

            Route.HomeComponentProfile ->
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
        ]
