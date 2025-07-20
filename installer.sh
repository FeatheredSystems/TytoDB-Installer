printf "Installing TytoDB.\n== Steps:\n1. Check if rustup is installed\n2. Check if cargo is installed\n3. Check if the OS is linux\n4. Check if the kernel version is compatible (have to be IO-uring compatible)\n5. Download source code\n6. Finish installation\n"

read -p "Run step 1? [Y/n] " answer
case $answer in
    [Yy]* ) ;;
    * ) echo "Aborting..."; exit 1;;
esac

RUSTUP_INSTALLED=false
while [ "$RUSTUP_INSTALLED" != true ]; do
    if command -v rustup >/dev/null 2>&1; then
        echo "rustup is installed"
        RUSTUP_INSTALLED=true
    else
        echo "rustup is not installed"
        read -p "Would you like to install rustup? [Y/n] " answer
        case $answer in
            [Yy]* ) curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh ;;
            * ) echo "Aborting..."; exit 1;;
        esac
    fi
done

CARGO_INSTALLED=false
while [ "$CARGO_INSTALLED" != true ]; do
    if command -v cargo >/dev/null 2>&1; then
        echo "cargo is installed"
        CARGO_INSTALLED=true
    else
        echo "cargo is not installed"
        # cargo should be installed with rustup, so prompt to install rustup again
        read -p "Would you like to install cargo (via rustup)? [Y/n] " answer
        case $answer in 
            [Yy]* ) curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh ;;
            * ) echo "Aborting..."; exit 1;;
        esac
    fi
done

