# This ci is a template for build riscv-gnu-toolchain and test it with spike simulator


git clone https://github.com/Liaoshihua/riscv-gnu-toolchain.git --recursive 

cd riscv-gnu-toolchain

# you can change your gcc repo to riscv-gcc/
# git remote add naem (your gcc repo)
# git remote update
# git checkout name/branch
# cd ..

# you can change your binutils repo to riscv-binutils/
# git remote add name (your binutils repo)
# git remote update
# git checkout name/branch
# cd ..


# you can change your spike repo to spike/
# cd spike 
# git remote add name (your repo)
# git remote update 
# git checkout name/branch
# cd ..

./configure --prefix="$PWD/opt-riscv-rv64/"

make report -j$(nproc)
