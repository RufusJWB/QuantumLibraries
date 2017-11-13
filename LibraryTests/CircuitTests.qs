// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

namespace Microsoft.Quantum.Tests {
    open Microsoft.Quantum.Primitive;
    open Microsoft.Quantum.Canon;


    // Tests of Margolus, Toffoli, and Fredkin gate implementations
    operation PhaseToffoliTestHelper ( qs : Qubit[] ) : () {
        body {
            // Essentially the definition of PhaseToffoli
            CCNOT( qs[2],qs[1],qs[0] );
            (Controlled (Adjoint S))([qs[2]],qs[1]);
        }
        adjoint auto
        controlled auto
        adjoint controlled auto
    }

    /// # Summary
    /// Checks that Toffoli is equal to Margolus up to relative phase in computational basis
    operation PhaseToffoliTest () : () {
        body {
            AssertOperationsEqualInPlace(PhaseToffoli1,PhaseToffoliTestHelper,3);
            // checking equality on the vectors of computational basis is not sensitive to phases
            AssertOperationsEqualInPlaceCompBasis(PhaseToffoli1,ToffoliTestHelper,3);
            AssertOperationsEqualInPlaceCompBasis(PhaseToffoli2,ToffoliTestHelper,3);
        }
    }

    operation ToffoliTestHelper( qs : Qubit[] ) : () {
        body{
            AssertIntEqual( Length(qs), 3 , "Toffoli gate takes three inputs");
            // we are testing against CCNOT that is a part of primitive operations
            CCNOT( qs[2],qs[1],qs[0] );
        }
        adjoint auto
        controlled auto 
        adjoint controlled auto
    }


    operation ToffoliTest () : () {
        body {
            AssertOperationsEqualInPlace(Toffoli1, ToffoliTestHelper, 3);
            AssertOperationsEqualInPlace(Toffoli2, ToffoliTestHelper, 3);
            AssertOperationsEqualInPlace(Toffoli3, ToffoliTestHelper, 3);
            AssertOperationsEqualInPlace(Toffoli4, ToffoliTestHelper, 3);
        }
    }

    operation FredkinTestHelper( qs : Qubit[] ) : () {
        body{
            AssertIntEqual( Length(qs), 3 , "Fredkin gate takes three inputs");
            // we are testing against Controlled SWAP that is a part of primitive operations
            (Controlled SWAP)( [qs[2]],(qs[0],qs[1]) );
        }
        adjoint auto
        controlled auto 
        adjoint controlled auto
    }

    operation FredkinTest () : () {
        body {
            AssertOperationsEqualInPlace(Fredkin1, FredkinTestHelper, 3);
            AssertOperationsEqualInPlace(Fredkin2, FredkinTestHelper, 3);
        }
    }
}