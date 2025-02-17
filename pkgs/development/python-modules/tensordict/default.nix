{
  lib,
  buildPythonPackage,
  pythonOlder,
  fetchFromGitHub,

  # build-system
  setuptools,
  torch,
  which,

  # dependencies
  cloudpickle,
  numpy,
  orjson,

  # checks
  h5py,
  pytestCheckHook,

  stdenv,
}:

buildPythonPackage rec {
  pname = "tensordict";
  version = "0.6.2";
  pyproject = true;

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "pytorch";
    repo = "tensordict";
    tag = "v${version}";
    hash = "sha256-dsbpk0O5Gs5WUfi3ENqHdpy4rWoBjm1i44+ycp0jDJ0=";
  };

  build-system = [
    setuptools
    torch
    which
  ];

  dependencies = [
    cloudpickle
    numpy
    orjson
    torch
  ];

  pythonImportsCheck = [ "tensordict" ];

  # We have to delete the source because otherwise it is used instead of the installed package.
  preCheck = ''
    rm -rf tensordict
  '';

  nativeCheckInputs = [
    h5py
    pytestCheckHook
  ];

  disabledTests =
    [
      # Hangs forever
      "test_copy_onto"

      # EOFError (MPI related)
      # AssertionError: assert tensor(False)
      # +  where tensor(False) = <built-in method all of Tensor object at 0x7ffe49bf87d0>()
      "test_mp"

      # torch._dynamo.exc.InternalTorchDynamoError: RuntimeError: to_module requires TORCHDYNAMO_INLINE_INBUILT_NN_MODULES to be set.
      "test_functional"

      # hangs forever on some CPUs
      "test_map_iter_interrupt_early"
    ]
    ++ lib.optionals (stdenv.hostPlatform.system == "aarch64-linux") [
      # RuntimeError: internal error
      "test_add_scale_sequence"
      "test_modules"
      "test_setattr"

      # _queue.Empty errors in multiprocessing tests
      "test_isend"
    ];

  disabledTestPaths = lib.optionals stdenv.hostPlatform.isDarwin [
    # torch._dynamo.exc.BackendCompilerFailed: backend='inductor' raised:
    # OpenMP support not found.
    "test/test_compile.py"

    # ModuleNotFoundError: No module named 'torch._C._distributed_c10d'; 'torch._C' is not a package
    "test/test_distributed.py"
  ];

  meta = {
    description = "Pytorch dedicated tensor container";
    changelog = "https://github.com/pytorch/tensordict/releases/tag/${src.tag}";
    homepage = "https://github.com/pytorch/tensordict";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ GaetanLepage ];
  };
}
