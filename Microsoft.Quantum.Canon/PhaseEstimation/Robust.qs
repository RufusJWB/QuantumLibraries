// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

namespace Microsoft.Quantum.Canon {
    open Microsoft.Quantum.Primitive;
    open Microsoft.Quantum.Extensions.Convert;
    open Microsoft.Quantum.Extensions.Math;

    /// # Summary
    /// Performs the robust non-terative quantum phase estimation algorithm for a given oracle U and eigenstate,
    /// and provides a single real-valued estimate of the phase with variance scaling at the Heisenberg limit.
    ///
    /// # Input
    /// ## oracle
    /// An operation implementing U^m for given integer powers m.
    /// ## eigenstate
    /// A quantum register representing an eigenstate |φ> of U, U|φ> =
    /// e^{iφ} |φ> for φ ∈ [0, 2π) an unknown phase.
    /// ## bitsPrecision
    /// This provides an estimate of φ with standard deviation
    /// σ <= 2π / 2^bitsPrecision using Queries scaling like σ <= 10.7 Pi/ Queries.
    ///
    /// # Remarks
    /// In the limit of a large number of queries, Cramer-Rao lower bounds
    /// for the standard deviation of the estimate of φ satisfy
    /// $\sigma \ge 2 \pi / \text{# of queries}$.
    /// 
    /// # References
    /// - Robust Calibration of a Universal Single-Qubit Gate-Set via Robust Phase Estimation
    ///   Shelby Kimmel, Guang Hao Low, Theodore J. Yoder
    ///   https://arxiv.org/abs/1502.02677
    operation RobustPhaseEstimation(bitsPrecision : Int, oracle : DiscreteOracle, eigenstate : Qubit[])  : Double
    {
        body {
            let alpha = 2.5;
            let beta = 0.5;
            mutable thetaEst = ToDouble(0);

            using (qubitAncilla = Qubit[1]) {
                let q = qubitAncilla[0];

                for (exponent in 0..bitsPrecision - 1) {

                    let power = 2 ^ (exponent);
                    mutable nRepeats = Ceiling(alpha * ToDouble(bitsPrecision - exponent) + beta);
                    if (nRepeats % 2 == 1) {
                        set nRepeats = nRepeats + 1;
                    }

                    mutable pZero = ToDouble(0);
                    mutable pPlus = ToDouble(0);

                    for (idxRep in 0..nRepeats-1) {
                        for (idxExperiment in 0..1) {
                            // Divide rotation by power to cancel the multiplication by power in DiscretePhaseEstimationIteration
                            let rotation = PI() * Float(idxExperiment) / 2.0 / Float(power);
                            DiscretePhaseEstimationIteration(oracle , power , rotation, eigenstate, q);
                            let result = M(q);

                            if (result== Zero) {
                                if (idxExperiment == 0) {
                                    set pZero = pZero + 1.0;
                                }
                                elif (idxExperiment == 1) {
                                    set pPlus = pPlus + 1.0;
                                }
                            }
                            Reset(q);
                        }
                    }
                    let deltaTheta = ArcTan2(pPlus - ToDouble(nRepeats) / 2.0,  pZero - ToDouble(nRepeats) / 2.0);
                    let delta = RealMod( deltaTheta - thetaEst * ToDouble(power), 2.0 * PI(), - PI());
                    set thetaEst = thetaEst + delta / ToDouble(power);
                }
                Reset(q);
            }
            return thetaEst;
        }
    }

    // Test is WIP
    operation RobustPhaseEstimationTestOp(phase: Double, power: Int, qubits : Qubit[]) : (){
        body {
            //Rz(- 2.0* phase * ToDouble(power), qubits[0])
            Exp([PauliZ], phase * ToDouble(power), qubits);
        }
        adjoint auto
        controlled auto
        controlled adjoint auto
    }

    // FIXME: check if this is still used anywhere.
    operation RobustPhaseEstimationDemo(phaseSet : Double, bitsPrecision: Int) : Double{
        body {
            let op = DiscreteOracle(RobustPhaseEstimationTestOp(phaseSet, _, _));
            mutable phaseEst = ToDouble(0);
            using (q = Qubit[1]) {
                set phaseEst = RobustPhaseEstimation(bitsPrecision, op, q);
                ResetAll(q);
            }
            return phaseEst;
        }
    }

    // Probabilistic test. Might fail occasionally
    operation RobustPhaseEstimationTest() : () {
        body {

            let bitsPrecision = 10;

            for (idxTest in 0..9) {
                let phaseSet = 2.0 * PI() * Float(idxTest - 5) / 12.0;
                let phaseEst = RobustPhaseEstimationDemo(phaseSet, bitsPrecision);
                AssertAlmostEqualTol(phaseEst, phaseSet, 1e-2);
            }
        }
    }

}