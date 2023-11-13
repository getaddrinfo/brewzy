use crate::prelude::*;
use ruby::backend::extn::prelude::InitializeResult;

use ruby::backend::{sys, unwrap_interpreter, mrb_get_args};

use ruby::prelude::*;

use std::ffi::CStr;

static DEMO_RUBY_SOURCE: &[u8] = include_bytes!("demo.rb");
static DEMO_RUBY_CSTR: &CStr = const_cstr_from_str!("Demo\0");

pub struct Demo;

pub fn init(interp: &mut Artichoke) -> InitializeResult<()> {
    let spec = ruby::backend::class::Spec::new("Demo", DEMO_RUBY_CSTR, None, None)?;
    ruby::backend::class::Builder::for_spec(interp, &spec)
        .add_method("native", native, sys::mrb_args_none())?
        .define()?;

    interp.def_class::<Demo>(spec)?;
    interp.eval(DEMO_RUBY_SOURCE)?;

    Ok(())
}

// from what I can tell, I don't have to do anything with `_slf``
unsafe extern "C" fn native(mrb: *mut sys::mrb_state, _slf: sys::mrb_value) -> sys::mrb_value {
    mrb_get_args!(mrb, none);
    unwrap_interpreter!(mrb, to => guard);

    guard.try_convert_mut("native").expect("to be successfully created").into()
}