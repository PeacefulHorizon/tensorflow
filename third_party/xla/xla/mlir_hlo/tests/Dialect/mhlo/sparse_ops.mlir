// RUN: mlir-hlo-opt %s -verify-diagnostics -allow-unregistered-dialect | FileCheck %s

// Tests for sparse types. Note that most dense MHLO ops can be made sparse
// by simply annotating one or more of the tensor types as sparse. Other than
// subtle printing and parsing difference (due to having different input and
// output types), dense or sparse ops are semantically equivalent.

#SV = #sparse_tensor.encoding<{
  map = (d0) -> (d0 : compressed)
}>

#CSR = #sparse_tensor.encoding<{
  map = (d0, d1) -> (d0 : dense, d1 : compressed)
}>

#DCSR = #sparse_tensor.encoding<{
  map = (d0, d1) -> (d0 : compressed, d1 : compressed)
}>

//
// Dense unary and binary eltwise.
//

// CHECK-LABEL: func @dense_abs_eltwise(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32>)
//       CHECK: %[[T:.*]] = mhlo.abs %[[A]] : tensor<10x20xf32>
//       CHECK: return %[[T]] : tensor<10x20xf32>
func.func @dense_abs_eltwise(%arg0: tensor<10x20xf32>) -> tensor<10x20xf32> {
  %0 = mhlo.abs %arg0 : tensor<10x20xf32>
  func.return %0 : tensor<10x20xf32>
}

// CHECK-LABEL: func @dense_add_eltwise(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32>,
//  CHECK-SAME: %[[B:.*]]: tensor<10x20xf32>)
//       CHECK: %[[T:.*]] = mhlo.add %[[A]], %[[B]] : tensor<10x20xf32>
//       CHECK: return %[[T]] : tensor<10x20xf32>
func.func @dense_add_eltwise(%arg0: tensor<10x20xf32>,
                        %arg1: tensor<10x20xf32>) -> tensor<10x20xf32> {
  %0 = mhlo.add %arg0, %arg1 : tensor<10x20xf32>
  func.return %0 : tensor<10x20xf32>
}

//
// Sparse unary eltwise.
//

// CHECK-LABEL: func @sparse_abs_eltwise1(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.abs %[[A]] : (tensor<10x20xf32, #{{.*}}>) -> tensor<10x20xf32>
//       CHECK: return %[[T]] : tensor<10x20xf32>
func.func @sparse_abs_eltwise1(%arg0: tensor<10x20xf32, #CSR>) -> tensor<10x20xf32> {
  %0 = mhlo.abs %arg0 : (tensor<10x20xf32, #CSR>) -> tensor<10x20xf32>
  func.return %0 : tensor<10x20xf32>
}

// CHECK-LABEL: func @sparse_abs_eltwise2(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.abs %[[A]] : tensor<10x20xf32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<10x20xf32, #{{.*}}>
func.func @sparse_abs_eltwise2(%arg0: tensor<10x20xf32, #CSR>) -> tensor<10x20xf32, #CSR> {
  %0 = mhlo.abs %arg0  : tensor<10x20xf32, #CSR>
  func.return %0 : tensor<10x20xf32, #CSR>
}

// CHECK-LABEL: func @sparse_abs_eltwise3(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.abs %[[A]] : (tensor<10x20xf32, #{{.*}}>) -> tensor<10x20xf32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<10x20xf32, #{{.*}}>
func.func @sparse_abs_eltwise3(%arg0: tensor<10x20xf32, #CSR>) -> tensor<10x20xf32, #DCSR> {
  %0 = mhlo.abs %arg0 : (tensor<10x20xf32, #CSR>) -> tensor<10x20xf32, #DCSR>
  func.return %0 : tensor<10x20xf32, #DCSR>
}

// CHECK-LABEL: func @sparse_abs_eltwise4(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32>)
//       CHECK: %[[T:.*]] = mhlo.abs %[[A]] : (tensor<10x20xf32>) -> tensor<10x20xf32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<10x20xf32, #{{.*}}>
func.func @sparse_abs_eltwise4(%arg0: tensor<10x20xf32>) -> tensor<10x20xf32, #CSR> {
  %0 = mhlo.abs %arg0 : (tensor<10x20xf32>) -> tensor<10x20xf32, #CSR>
  func.return %0 : tensor<10x20xf32, #CSR>
}

// CHECK-LABEL: func @sparse_conv_eltwise1(
//  CHECK-SAME: %[[A:.*]]: tensor<2x3xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.convert %[[A]] : (tensor<2x3xf32, #{{.*}}>) -> tensor<2x3xi32>
//       CHECK: return %[[T]] : tensor<2x3xi32>
func.func @sparse_conv_eltwise1(%arg0: tensor<2x3xf32, #CSR>) -> tensor<2x3xi32> {
  %0 = mhlo.convert %arg0 : (tensor<2x3xf32, #CSR>) -> tensor<2x3xi32>
  return %0 : tensor<2x3xi32>
}

// CHECK-LABEL: func @sparse_conv_eltwise2(
//  CHECK-SAME: %[[A:.*]]: tensor<2x3xf32>)
//       CHECK: %[[T:.*]] = mhlo.convert %[[A]] : (tensor<2x3xf32>) -> tensor<2x3xi32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<2x3xi32, #{{.*}}>
func.func @sparse_conv_eltwise2(%arg0: tensor<2x3xf32>) -> tensor<2x3xi32, #CSR> {
  %0 = mhlo.convert %arg0 : (tensor<2x3xf32>) -> tensor<2x3xi32, #CSR>
  return %0 : tensor<2x3xi32, #CSR>
}

// CHECK-LABEL: func @sparse_conv_eltwise3(
//  CHECK-SAME: %[[A:.*]]: tensor<2x3xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.convert %[[A]] : (tensor<2x3xf32, #{{.*}}>) -> tensor<2x3xi32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<2x3xi32, #{{.*}}>
func.func @sparse_conv_eltwise3(%arg0: tensor<2x3xf32, #CSR>) -> tensor<2x3xi32, #CSR> {
  %0 = mhlo.convert %arg0 : (tensor<2x3xf32, #CSR>) -> tensor<2x3xi32, #CSR>
  return %0 : tensor<2x3xi32, #CSR>
}

//
// Sparse binary eltwise.
//

// CHECK-LABEL: func @sparse_add_eltwise1(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32, #{{.*}}>,
//  CHECK-SAME: %[[B:.*]]: tensor<10x20xf32>)
//       CHECK: %[[T:.*]] = mhlo.add %[[A]], %[[B]] : (tensor<10x20xf32, #{{.*}}>, tensor<10x20xf32>) -> tensor<10x20xf32>
//       CHECK: return %[[T]] : tensor<10x20xf32>
func.func @sparse_add_eltwise1(%arg0: tensor<10x20xf32, #CSR>,
                               %arg1: tensor<10x20xf32>) -> tensor<10x20xf32> {
  %0 = mhlo.add %arg0, %arg1 : (tensor<10x20xf32, #CSR>,
                                 tensor<10x20xf32>) -> tensor<10x20xf32>
  func.return %0 : tensor<10x20xf32>
}

// CHECK-LABEL: func @sparse_add_eltwise2(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32, #{{.*}}>,
//  CHECK-SAME: %[[B:.*]]: tensor<10x20xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.add %[[A]], %[[B]] : (tensor<10x20xf32, #{{.*}}>, tensor<10x20xf32, #{{.*}}>) -> tensor<10x20xf32>
//       CHECK: return %[[T]] : tensor<10x20xf32>
func.func @sparse_add_eltwise2(%arg0: tensor<10x20xf32, #CSR>,
                               %arg1: tensor<10x20xf32, #DCSR>)
                                   -> tensor<10x20xf32> {
  %0 = mhlo.add %arg0, %arg1 : (tensor<10x20xf32, #CSR>,
                                 tensor<10x20xf32, #DCSR>) -> tensor<10x20xf32>
  func.return %0 : tensor<10x20xf32>
}

// CHECK-LABEL: func @sparse_add_eltwise3(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32, #{{.*}}>,
//  CHECK-SAME: %[[B:.*]]: tensor<10x20xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.add %[[A]], %[[B]] : (tensor<10x20xf32, #{{.*}}>, tensor<10x20xf32, #{{.*}}>) -> tensor<10x20xf32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<10x20xf32, #{{.*}}>
func.func @sparse_add_eltwise3(%arg0: tensor<10x20xf32, #CSR>,
                               %arg1: tensor<10x20xf32, #DCSR>)
                                   -> tensor<10x20xf32, #CSR> {
  %0 = mhlo.add %arg0, %arg1 : (tensor<10x20xf32, #CSR>,
                                 tensor<10x20xf32, #DCSR>) -> tensor<10x20xf32, #CSR>
  func.return %0 : tensor<10x20xf32, #CSR>
}

// CHECK-LABEL: func @sparse_add_eltwise4(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32>,
//  CHECK-SAME: %[[B:.*]]: tensor<10x20xf32>)
//       CHECK: %[[T:.*]] = mhlo.add %[[A]], %[[B]] : (tensor<10x20xf32>, tensor<10x20xf32>) -> tensor<10x20xf32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<10x20xf32, #{{.*}}>
func.func @sparse_add_eltwise4(%arg0: tensor<10x20xf32>,
                               %arg1: tensor<10x20xf32>)
                                   -> tensor<10x20xf32, #CSR> {
  %0 = mhlo.add %arg0, %arg1 : (tensor<10x20xf32>,
                                 tensor<10x20xf32>) -> tensor<10x20xf32, #CSR>
  func.return %0 : tensor<10x20xf32, #CSR>
}

// CHECK-LABEL: func @sparse_add_eltwise5(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32, #{{.*}}>,
//  CHECK-SAME: %[[B:.*]]: tensor<10x20xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.add %[[A]], %[[B]] : tensor<10x20xf32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<10x20xf32, #{{.*}}>
func.func @sparse_add_eltwise5(%arg0: tensor<10x20xf32, #CSR>,
                               %arg1: tensor<10x20xf32, #CSR>)
                                   -> tensor<10x20xf32, #CSR> {
  %0 = mhlo.add %arg0, %arg1 : tensor<10x20xf32, #CSR>
  func.return %0 : tensor<10x20xf32, #CSR>
}

// CHECK-LABEL: func @sparse_mul_eltwise1(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32, #{{.*}}>,
//  CHECK-SAME: %[[B:.*]]: tensor<10x20xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.multiply %[[A]], %[[B]] : tensor<10x20xf32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<10x20xf32, #{{.*}}>
func.func @sparse_mul_eltwise1(%arg0: tensor<10x20xf32, #CSR>,
                               %arg1: tensor<10x20xf32, #CSR>)
                                   -> tensor<10x20xf32, #CSR> {
  %0 = mhlo.multiply %arg0, %arg1 : tensor<10x20xf32, #CSR>
  func.return %0 : tensor<10x20xf32, #CSR>
}

// CHECK-LABEL: func @sparse_mul_eltwise2(
//  CHECK-SAME: %[[A:.*]]: tensor<10x20xf32>,
//  CHECK-SAME: %[[B:.*]]: tensor<10x20xf32, #{{.*}}>)
//       CHECK: %[[T:.*]] = mhlo.multiply %[[A]], %[[B]] : (tensor<10x20xf32>, tensor<10x20xf32, #{{.*}}>) -> tensor<10x20xf32, #{{.*}}>
//       CHECK: return %[[T]] : tensor<10x20xf32, #{{.*}}>
func.func @sparse_mul_eltwise2(%arg0: tensor<10x20xf32>,
                               %arg1: tensor<10x20xf32, #CSR>)
                                   -> tensor<10x20xf32, #CSR> {
  %0 = mhlo.multiply %arg0, %arg1 : (tensor<10x20xf32>,
                                      tensor<10x20xf32, #CSR>) -> tensor<10x20xf32, #CSR>
  func.return %0 : tensor<10x20xf32, #CSR>
}

//
// Sparse dot operation.
//

// CHECK-LABEL: func @dot1(
//  CHECK-SAME: %[[A:.*]]: tensor<4xf64, #{{.*}}>,
//  CHECK-SAME: %[[B:.*]]: tensor<4xf64>) -> tensor<f64> {
//       CHECK: %[[T:.*]] = "mhlo.dot_general"(%[[A]], %[[B]]) {{{.*}}} : (tensor<4xf64, #{{.*}}>, tensor<4xf64>) -> tensor<f64>
//       CHECK: return %[[T]] : tensor<f64>
func.func @dot1(%arg0: tensor<4xf64, #SV>,
                %arg1: tensor<4xf64>) -> tensor<f64> {
  %0 = "mhlo.dot_general"(%arg0, %arg1)
     {dot_dimension_numbers = #mhlo.dot<lhs_contracting_dimensions = [0],
                                        rhs_contracting_dimensions = [0]>,
                                        precision_config = [#mhlo<precision DEFAULT>,
                                        #mhlo<precision DEFAULT>]}
           : (tensor<4xf64, #SV>, tensor<4xf64>) -> tensor<f64>
  func.return %0 : tensor<f64>
}

// CHECK-LABEL: func @dot2(
//  CHECK-SAME: %[[A:.*]]: tensor<4xf64>,
//  CHECK-SAME: %[[B:.*]]: tensor<4xf64, #{{.*}}>) -> tensor<f64> {
//       CHECK: %[[T:.*]] = "mhlo.dot_general"(%[[A]], %[[B]]) {{{.*}}} : (tensor<4xf64>, tensor<4xf64, #{{.*}}>) -> tensor<f64>
//       CHECK: return %[[T]] : tensor<f64>
func.func @dot2(%arg0: tensor<4xf64>,
                %arg1: tensor<4xf64, #SV>) -> tensor<f64> {
  %0 = "mhlo.dot_general"(%arg0, %arg1)
     {dot_dimension_numbers = #mhlo.dot<lhs_contracting_dimensions = [0],
                                        rhs_contracting_dimensions = [0]>,
                                        precision_config = [#mhlo<precision DEFAULT>,
                                        #mhlo<precision DEFAULT>]}
           : (tensor<4xf64>, tensor<4xf64, #SV>) -> tensor<f64>
  func.return %0 : tensor<f64>
}

// CHECK-LABEL: func @dot3(
//  CHECK-SAME: %[[A:.*]]: tensor<4xf64, #{{.*}}>,
//  CHECK-SAME: %[[B:.*]]: tensor<4xf64, #{{.*}}>) -> tensor<f64> {
//       CHECK: %[[T:.*]] = "mhlo.dot_general"(%[[A]], %[[B]]) {{{.*}}} : (tensor<4xf64, #{{.*}}>, tensor<4xf64, #{{.*}}>) -> tensor<f64>
//       CHECK: return %[[T]] : tensor<f64>
func.func @dot3(%arg0: tensor<4xf64, #SV>,
                %arg1: tensor<4xf64, #SV>) -> tensor<f64> {
  %0 = "mhlo.dot_general"(%arg0, %arg1)
     {dot_dimension_numbers = #mhlo.dot<lhs_contracting_dimensions = [0],
                                        rhs_contracting_dimensions = [0]>,
                                        precision_config = [#mhlo<precision DEFAULT>,
                                        #mhlo<precision DEFAULT>]}
           : (tensor<4xf64, #SV>, tensor<4xf64, #SV>) -> tensor<f64>
  func.return %0 : tensor<f64>
}

//
// Reduce.
//

// CHECK-LABEL: func @sparse_reduce(
//  CHECK-SAME: %[[A:.*]]: tensor<10xi64, #{{.*}}>) -> tensor<i64> {
//       CHECK: %[[C:.*]] = mhlo.constant dense<0> : tensor<i64>
//       CHECK: %[[T:.*]] = mhlo.reduce(%[[A]] init: %[[C]]) applies mhlo.add across dimensions = [0] : (tensor<10xi64, #{{.*}}>) -> tensor<i64>
//       CHECK: return %[[T]] : tensor<i64>
func.func @sparse_reduce(%arg0: tensor<10xi64, #SV>) -> tensor<i64> {
  %0 = mhlo.constant dense<0> : tensor<i64>
  %1 = mhlo.reduce(%arg0 init: %0) across dimensions = [0] : (tensor<10xi64, #SV>, tensor<i64>) -> tensor<i64>
   reducer(%arg1: tensor<i64>, %arg2: tensor<i64>)  {
    %2 = mhlo.add %arg1, %arg2 : tensor<i64>
    "mhlo.return"(%2) : (tensor<i64>) -> ()
  }
  func.return %1 : tensor<i64>
}

//
// Transpose.
//

// CHECK-LABEL: func @sparse_transpose(
//  CHECK-SAME: %[[A:.*]]: tensor<100x100xf64, #{{.*}}>) -> tensor<100x100xf64, #{{.*}}> {
//       CHECK: %[[T:.*]] = "mhlo.transpose"(%[[A]]) {{{.*}}} : (tensor<100x100xf64, #{{.*}}>) -> tensor<100x100xf64, #{{.*}}>
//       CHECK: return %[[T]] : tensor<100x100xf64, #{{.*}}>
func.func @sparse_transpose(%arg0: tensor<100x100xf64, #CSR>)
                                -> tensor<100x100xf64, #DCSR> {
  %0 = "mhlo.transpose"(%arg0) {permutation = dense<[1, 0]> : tensor<2xi64>}
     : (tensor<100x100xf64, #CSR>) -> tensor<100x100xf64, #DCSR>
  func.return %0 : tensor<100x100xf64, #DCSR>
}

//
// Math.
//

// CHECK-LABEL: func @sparse_zero_preserving_math(
//  CHECK-SAME: %[[A:.*]]: tensor<64xf64, #{{.*}}>)
//       CHECK: %[[T0:.*]] = mhlo.abs %[[A]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T1:.*]] = mhlo.exponential_minus_one %[[T0]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T2:.*]] = mhlo.log_plus_one %[[T1]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T3:.*]] = mhlo.negate %[[T2]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T4:.*]] = mhlo.sign %[[T3]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T5:.*]] = mhlo.sine %[[T4]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T6:.*]] = mhlo.sqrt %[[T5]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T7:.*]] = mhlo.tanh %[[T6]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T8:.*]] = mhlo.ceil %[[T7]] : tensor<64xf64, #{{.*}}>
//       CHECK: %[[T9:.*]] = mhlo.floor %[[T8]] : tensor<64xf64, #{{.*}}>
//       CHECK: return %[[T9]] : tensor<64xf64, #{{.*}}>
func.func @sparse_zero_preserving_math(%arg0: tensor<64xf64, #SV>) -> tensor<64xf64, #SV> {
  %0 = mhlo.abs %arg0 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %1 = mhlo.exponential_minus_one %0 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %2 = mhlo.log_plus_one %1 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %3 = mhlo.negate %2 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %4 = mhlo.sign %3 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %5 = mhlo.sine %4 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %6 = mhlo.sqrt %5 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %7 = mhlo.tanh %6 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %8 = mhlo.ceil %7 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  %9 = mhlo.floor %8 : (tensor<64xf64, #SV>) -> tensor<64xf64, #SV>
  func.return %9 : tensor<64xf64, #SV>
}

//
// Combination of quantization and sparse.
//

// CHECK-LABEL: func @quantization_and_sparse(
//  CHECK-SAME: %[[A:.*]]: tensor<1x!quant.uniform<i8:f32, 1.000000e+00:17>, #{{.*}}>)
//       CHECK: return %[[A]] : tensor<1x!quant.uniform<i8:f32, 1.000000e+00:17>, #{{.*}}>
func.func @quantization_and_sparse(%arg0: tensor<1x!quant.uniform<i8:f32, 1.0:17>, #SV>)
                                       -> tensor<1x!quant.uniform<i8:f32, 1.0:17>, #SV> {
  func.return %arg0 : tensor<1x!quant.uniform<i8:f32, 1.0:17>, #SV>
}
