module SubHask.TemplateHaskell.Test
    where

import Prelude
import Control.Monad

import qualified Data.Map as Map
import Debug.Trace

import Language.Haskell.TH
import GHC.Exts

import SubHask.Internal.Prelude
import SubHask.TemplateHaskell.Deriving
-- import SubHask.Category
-- import SubHask.Algebra

-- | Ideally, this map would be generated automatically via template haskell.
-- Due to bug <https://ghc.haskell.org/trac/ghc/ticket/9699 #9699>, however, we must enter these manually.
testMap :: Map.Map String [String]
testMap = Map.fromList
    [ ( "Eq",[] )
    , ( "InfSemilatice",[])
    , ( "MinBound",[])
    , ( "Lattice",[])
    , ( "Ord",[])
    , ( "POrd",[])

    , ( "Eq_",
        [ "law_Eq_reflexive"
        , "law_Eq_symmetric"
        , "law_Eq_transitive"
        ] )
    , ( "POrd_",
        [ "law_POrd_commutative"
        , "law_POrd_associative"
        , "theorem_POrd_idempotent"
        ])
    , ("MinBound_",
        [ "law_MinBound_inf"
        ] )
    , ( "Lattice_",
        [ "law_Lattice_infabsorption"
        , "law_Lattice_supabsorption"
        ] )
--     , ( "Ord_",[])
    , ( "Ord_",
        [ "law_Ord_totality"
        , "law_Ord_min"
        , "law_Ord_max"
        ] )
    , ("Bounded",
        [ "law_Bounded_sup"
        ] )
    , ("Complemented",
        [ "law_Complemented_not"
        ] )
    , ("Heyting",
        [ "law_Heyting_maxbound"
        , "law_Heyting_infleft"
        , "law_Heyting_infright"
        , "law_Heyting_distributive"
        ] )
    , ("Boolean",
        [ "law_Boolean_infcomplement"
        , "law_Boolean_supcomplement"
        , "law_Boolean_infdistributivity"
        , "law_Boolean_supdistributivity"
        ])
    , ( "Graded",
        [ "law_Graded_pred"
        , "law_Graded_fromEnum"
        ] )
    , ( "Enum",
        [ "law_Enum_succ"
        , "law_Enum_toEnum"
        ] )



    , ( "Semigroup" ,
        [ "law_Semigroup_associativity"
        ] )
    , ( "Cancellative",
        [ "law_Cancellative_rightminus1"
        , "law_Cancellative_rightminus2"
        ])
    , ( "Monoid",
        [ "law_Monoid_leftid"
        , "law_Monoid_rightid"
        , "defn_Monoid_isZero"
        ] )
    , ( "Abelian",
        [ "law_Abelian_commutative"
        ] )
    , ( "Group",
        [ "defn_Group_negateminus"
        , "law_Group_leftinverse"
        , "law_Group_rightinverse"
        ] )

    , ("Rg",
        [ "law_Rg_multiplicativeAssociativity"
        , "law_Rg_multiplicativeCommutivity"
        , "law_Rg_annihilation"
        , "law_Rg_distributivityLeft"
        , "theorem_Rg_distributivityRight"
        ])
    , ("Rig",
        [ "law_Rig_multiplicativeId"
        ] )
    , ("Rng", [])
    , ("Ring",
        [ "defn_Ring_fromInteger"
        ] )
    , ("Integral",
        [ "law_Integral_divMod"
        , "law_Integral_quotRem"
        , "law_Integral_toFromInverse"
        ])

    , ( "HasScalar", [] )
    , ( "Normed",
        [
        ] )
    , ( "MetricSpace",
        [ "law_MetricSpace_nonnegativity"
        , "law_MetricSpace_indiscernables"
        , "law_MetricSpace_symmetry"
        , "law_MetricSpace_triangle"
        ] )

    , ( "Container",
        [ "law_Container_preservation"
        , "law_Constructible_singleton"
        , "theorem_Constructible_insert"
        ] )
    , ( "Indexed",
        [ "law_Indexed_cons"
        ] )

    , ( "Constructible",
        [ "defn_Constructible_cons"
        , "defn_Constructible_snoc"
        , "defn_Constructible_fromList"
        , "defn_Constructible_fromListN"
        ] )
    , ( "Unfoldable",
        [
--         [ "law_Container_empty"
--         , "law_Container_MonoidMinBound"
--         , "law_Container_MonoidNormed"
--         , "defn_Container_infDisjoint"
--         , "defn_Container_null"
        ] )
    , ( "Foldable",
        [
        ] )
    , ( "Partitionable",
        [ "law_Partitionable_length"
        , "law_Partitionable_monoid"
        ] )
    , ( "FreeMonoid", [])
    ]

-- | makes tests for all instances of a class that take no type variables
mkClassTests :: Name -> Q Exp
mkClassTests className = do
    info <- reify className
    typeTests <- case info of
        ClassI _ xs -> go xs
        otherwise -> error "mkClassTests called on something not a class"
    return $ AppE
        ( AppE
            ( VarE $ mkName "testGroup" )
            ( LitE $ StringL $ nameBase className )
        )
        ( typeTests )
    where
        go [] = return $ ConE $ mkName "[]"
        go ((InstanceD ctx (AppT _ t) _):xs) = case t of
            (ConT a) -> do
                tests <- mkSpecializedClassTest (ConT a) className
                next <- go xs
                return $ AppE
                    ( AppE
                        ( ConE $ mkName ":" )
                        ( tests )
                    )
                    ( next )
--             (AppT _ _) -> do
--                 let specializedType = specializeType t (ConT ''Int)
--                 tests <- mkSpecializedClassTest specializedType className
--                 next <- go xs
--                 return $ AppE
--                     ( AppE
--                         ( ConE $ mkName ":" )
--                         ( tests )
--                     )
--                     ( next )
--             otherwise -> trace ("mkClassTests: skipping "++show ctx++" => "++show t) $ go xs
            otherwise -> go xs


-- | Given a type and a class, searches "testMap" for all tests for the class;
-- then specializes those tests to test on the given type
mkSpecializedClassTest
    :: Type -- ^ type to create tests for
    -> Name -- ^ class to create tests for
    -> Q Exp
mkSpecializedClassTest typeName className = case Map.lookup (nameBase className) testMap of
    Nothing -> error $ "mkSpecializedClassTest: no tests defined for type " ++ nameBase className
    Just xs -> do
        tests <- mkTests typeName $ map mkName xs
        return $ AppE
            ( AppE
                ( VarE $ mkName "testGroup" )
--                 ( LitE $ StringL $ show $ ppr typeName )
                ( LitE $ StringL $ nameBase className )
            )
            ( tests )

-- | Like "mkSpecializedClassTests", but takes a list of classes
mkSpecializedClassTests :: Q Type -> [Name] -> Q Exp
mkSpecializedClassTests typeNameQ xs = do
    typeName <- typeNameQ
    testnames <- liftM concat $ mapM listSuperClasses xs
    tests <- liftM listExp2Exp $ mapM (mkSpecializedClassTest typeName) testnames
    return $ AppE
        ( AppE
            ( VarE $ mkName "testGroup" )
            ( LitE $ StringL $ show $ ppr typeName )
        )
        ( tests )

-- | replace all variables with a concrete type
specializeType
    :: Type -- ^ type with variables
    -> Type -- ^ instantiate variables to this type
    -> Type
specializeType t n = case t of
    VarT _ -> n
    AppT t1 t2 -> AppT (specializeType t1 n) (specializeType t2 n)
    ForallT xs ctx t -> {-ForallT xs ctx $-} specializeType t n
--     ForallT xs ctx t -> ForallT xs (specializeType ctx n) $ specializeType t n
    x -> x

specializeLaw
    :: Type -- ^ type to specialize the law to
    -> Name -- ^ law (i.e. function) that we're testing
    -> Q Exp
specializeLaw typeName lawName = do
    lawInfo <- reify lawName
    let newType = case lawInfo of
            VarI _ t _ _ -> specializeType t typeName
            otherwise -> error "mkTest lawName not a function"
    return $ SigE (VarE lawName) newType

-- | creates an expression of the form:
--
-- > testProperty "testname" (law_Classname_testname :: typeName -> ... -> Bool)
--
mkTest
    :: Type -- ^ type to specialize the law to
    -> Name -- ^ law (i.e. function) that we're testing
    -> Q Exp
mkTest typeName lawName = do
    spec <- specializeLaw typeName lawName
    return $ AppE
        ( AppE
            ( VarE $ mkName "testProperty" )
            ( LitE $ StringL $ extractTestStr lawName )
        )
        ( spec )

-- | Like "mkTest", but takes a list of laws and returns a list of tests
mkTests :: Type -> [Name] -> Q Exp
mkTests typeName xs = liftM listExp2Exp $ mapM (mkTest typeName) xs

listExp2Exp :: [Exp] -> Exp
listExp2Exp [] = ConE $ mkName "[]"
listExp2Exp (x:xs) = AppE
    ( AppE
        ( ConE $ mkName ":" )
        ( x )
    )
    ( listExp2Exp xs )

-- | takes a "Name" of the form
--
-- > law_Class_test
--
-- and returns the string
--
-- > test
extractTestStr :: Name -> String
extractTestStr name = nameBase name
-- extractTestStr name = last $ words $ map (\x -> if x=='_' then ' ' else x) $ nameBase name

