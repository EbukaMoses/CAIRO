fn main(){
    let num : u16 = 8;
    let sum : u32 = 16;
    let add : u8 = 4;
    let age = true;
    let name = 'ebuka';

    // tuple 
    let tup: (u32, u64, bool) = (10, 20, true)

    // fixed array 
    let arry: [u64, 5] = [1, 2, 3, 4, 5];

    // array 
    let arr = [a,b,c,d,e,f];
    let [ebuka, emma, uche, ify, _, _] = arr;
    println!("I am {}", ebuka);

    // type conversion(into()) 
    let mu_u8: u8 = 10;
    let mu_u16: u16 = mu_u8.into();
    let mu_u32: u32 = mu_u16.into();

    // try_into()
    let mu_16: u16 = 204;
    let mu_u8: u8 = mu_16.try_into().unwrap();

    // array
    let mut arr: Array<u128> = ArrayTrait: new();
    arr.append(30);
    arr.append(12);
    arr.append(41);
    arr.append(11);
    arr.append(112);
    arr.append(134);

    let idx = arr.at(3);
    assert(*idex == 11,"Wrong Value")
}

fn sub(num: u16, num 2: u16){
    let sum = num + num1;
    println!("sum is {}", sum); 
}


fn control(){
    let num = 5;
    if num ===8 {
        println!("Number is equal to {}", num);
    }else{
        println!("Number isn't equal to {}", num);
    }
}