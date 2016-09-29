module Doc.Model exposing (Model, Clause, ClauseInfo, ClauseType, emptyDoc, addNewClause, newClause, newSponsor)

import Date exposing (Date)
import Dict exposing (Dict)


type alias Model =
    { title : String
    , meetingDate : Maybe Date
    , sponsors : Dict Int Sponsor
    , clauses : Dict Int Clause
    , validSponsors : List String
    , validClauseTypes : ClauseInfo
    , defaultClauseType : ClauseType
    }


type alias Sponsor =
    { name : String
    , pos : Int
    }


type alias Clause =
    { ctype : ClauseType
    , content : String
    , id : Int
    , pos : Int
    }


type alias ClauseInfo =
    Dict ClauseType ClauseTypeDesc


type alias ClauseType =
    String


type alias ClauseTypeDesc =
    { displayName : String
    , sortWeight : Int
    }


emptyDoc : Model
emptyDoc =
    { title = ""
    , meetingDate = Nothing
    , sponsors = Dict.empty
    , clauses =
        Dict.fromList <|
            List.indexedMap (\idx ctype -> ( idx, newClause idx (idx + 1) ctype "" ))
                [ "Whereas"
                , "Whereas"
                , "Whereas"
                ]
    , validSponsors = chicagoSponsors
    , validClauseTypes =
        Dict.fromList
            [ ( "Whereas", { displayName = "WHEREAS", sortWeight = 1 } )
            , ( "BeItResolved", { displayName = "BE IT RESOLVED", sortWeight = 2 } )
            , ( "BeItFurtherResolved", { displayName = "BE IT FURTHER RESOLVED", sortWeight = 3 } )
            ]
    , defaultClauseType = "Whereas"
    }


addNewClause : Int -> ClauseType -> Model -> Model
addNewClause id clauseType doc =
    let
        newClauses =
            Dict.insert id (newClause id ((Dict.size doc.clauses) + 1) clauseType "") doc.clauses
                |> sortClauses

        sortClauses clauses =
            clauses
                |> Dict.toList
                |> List.sortWith clauseCompare
                |> List.indexedMap (\idx ( id, clause ) -> ( id, { clause | pos = idx + 1 } ))
                |> Dict.fromList

        clauseCompare ( _, clauseA ) ( _, clauseB ) =
            let
                sortWeightA =
                    getClauseSortWeight clauseA.ctype

                sortWeightB =
                    getClauseSortWeight clauseB.ctype
            in
                if sortWeightA /= sortWeightB then
                    compare sortWeightA sortWeightB
                else
                    compare clauseA.pos clauseB.pos

        getClauseSortWeight clauseType =
            doc.validClauseTypes
                |> Dict.get clauseType
                |> Maybe.map .sortWeight
                |> Maybe.withDefault 0
    in
        { doc | clauses = newClauses }


newClause : Int -> Int -> ClauseType -> String -> Clause
newClause id pos ctype content =
    { ctype = ctype
    , content = content
    , id = id
    , pos = pos
    }


newSponsor : Int -> String -> Sponsor
newSponsor pos name =
    { name = name
    , pos = pos
    }


chicagoSponsors : List String
chicagoSponsors =
    [ "Arena, John (45)"
    , "Austin, Carrie M. (34)"
    , "Beale, Anthony (9)"
    , "Brookins, Jr., Howard (21)"
    , "Burke, Edward M. (14)"
    , "Burnett, Jr., Walter (27)"
    , "Cappleman, James (46)"
    , "Cardenas, George A. (12)"
    , "Cochran, Willie (20)"
    , "Curtis, Derrick G. (18)"
    , "Dowell, Pat (3)"
    , "Emanuel, Rahm (Mayor)"
    , "Ervin, Jason C. (28)"
    , "Foulkes, Toni (16)"
    , "Hairston, Leslie A. (5)"
    , "Harris, Michelle A. (8)"
    , "Hopkins, Brian (2)"
    , "King, Sophia (4)"
    , "Laurino, Margaret (39)"
    , "Lopez, Raymond A. (15)"
    , "Maldonado, Roberto (26)"
    , "Mell, Deborah (33)"
    , "Mendoza, Susana A. (Clerk)"
    , "Mitchell, Gregory I. (7)"
    , "Mitts, Emma (37)"
    , "Moore, David H. (17)"
    , "Moore, Joseph (49)"
    , "Moreno, Proco Joe (1)"
    , "Munoz, Ricardo (22)"
    , "Napolitano, Anthony V. (41)"
    , "O'Connor, Patrick (40)"
    , "O'Shea, Matthew J. (19)"
    , "Osterman, Harry (48)"
    , "Pawar, Ameya (47)"
    , "Quinn, Marty (13)"
    , "Ramirez-Rosa, Carlos (35)"
    , "Reboyras, Ariel (30)"
    , "Reilly, Brendan (42)"
    , "Sadlowski Garza, Susan (10)"
    , "Santiago, Milagros S. (31)"
    , "Sawyer, Roderick T. (6)"
    , "Scott, Jr. Michael (24)"
    , "Silverstein, Debra L. (50)"
    , "Smith, Michele (43)"
    , "Solis, Daniel (25)"
    , "Sposato, Nicholas (38)"
    , "Taliaferro, Chris (29)"
    , "Thompson, Patrick D. (11)"
    , "Tunney, Thomas (44)"
    , "Villegas, Gilbert (36)"
    , "Waguespack, Scott (32)"
    , "Zalewski, Michael R. (23)"
    ]
