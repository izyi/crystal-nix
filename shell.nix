(import
  (
    let
      flake = builtins.getFlake (toString ./.);
      system = builtins.currentSystem;
    in
      flake.outputs.devShells.${system}.default
  )
)
