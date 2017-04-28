module Models.Opinion exposing (..)

import Models.ContentPointer exposing (ContentPointer)
import Models.Rating exposing (Rating)


{-| An opinion on some specific content.

Parallels to the backend `Opinion` but we don't include the `userID`
-}
type alias Opinion =
    { contentPointer : ContentPointer
    , rating : Rating
    }


{-| An opinion (or lack of opinion) on some specific content.

Useful for rendering on the frontend where `Nothing` for the rating signafies that the user has no opinion.
-}
type alias MaybeOpinion =
    { contentPointer : ContentPointer
    , rating : Maybe Rating
    }


{-| Converting an `Opinion` to a `MaybeOpinion`.
-}
toMaybeOpinion : Opinion -> MaybeOpinion
toMaybeOpinion opinion =
    { contentPointer = opinion.contentPointer
    , rating = Just opinion.rating
    }
