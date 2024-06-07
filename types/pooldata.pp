type Lcmaps::PoolData = Struct[{
    name              => String,
    size              => Integer,
    base_uid          => Integer,
    group             => String,
    gid               => Integer,
    vo                => String,
    groups            => Optional[Array[String]],
    role              => Optional[String],
    roles             => Optional[Array[String]],
    capability        => Optional[String],
    create_pool_user  => Optional[Boolean],
    create_pool_group => Optional[Boolean],
    number_of_digits  => Optional[Integer],
    first_number      => Optional[Integer],
    step_number       => Optional[Integer],
}]
