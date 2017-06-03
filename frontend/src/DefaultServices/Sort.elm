module DefaultServices.Sort exposing (..)

import Date


{-| For comparing 2 instances of `t`.
-}
type alias Comparator t =
    t -> t -> Basics.Order


{-| When you only need to sort by a single comparator.

Wrapper around `List.sortWith` so all sorting can be performed with this module.
-}
sortBy : Comparator t -> List t -> List t
sortBy comparator =
    List.sortWith comparator


{-| To be able to sort by multiple comparators (for breaking ties).
-}
sortByAll : List (Comparator t) -> List t -> List t
sortByAll comparators =
    sortBy
        (\prev next ->
            let
                go comparators =
                    case comparators of
                        [] ->
                            Basics.EQ

                        comparator :: restOfComparators ->
                            case comparator prev next of
                                Basics.LT ->
                                    Basics.LT

                                Basics.GT ->
                                    Basics.GT

                                Basics.EQ ->
                                    go restOfComparators
            in
                go comparators
        )


{-| Creates a comparator for `t`.
-}
createComparator : (t -> comparable) -> Comparator t
createComparator toComparable t1 t2 =
    Basics.compare (toComparable t1) (toComparable t2)


{-| For comparing boolean values, True < False.
-}
createBoolComparator : (t -> Bool) -> Comparator t
createBoolComparator toBool t1 t2 =
    case ( toBool t1, toBool t2 ) of
        ( True, False ) ->
            Basics.LT

        ( False, True ) ->
            Basics.GT

        _ ->
            Basics.EQ


{-| For comparing dates, earlier-date < later-date.
-}
createDateComparator : (t -> Date.Date) -> Comparator t
createDateComparator toDate t1 t2 =
    Basics.compare (Date.toTime <| toDate <| t1) (Date.toTime <| toDate <| t2)


{-| Helper for reversing a comparator.
-}
reverseComparator : Comparator t -> Comparator t
reverseComparator comparator t1 t2 =
    comparator t1 t2 |> reverseOrder


{-| Reverses the order.
-}
reverseOrder : Basics.Order -> Basics.Order
reverseOrder order =
    case order of
        Basics.LT ->
            Basics.GT

        Basics.GT ->
            Basics.LT

        Basics.EQ ->
            Basics.EQ
