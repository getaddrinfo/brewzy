

use std::ffi::OsString;
use std::os::unix::prelude::OsStrExt;
use std::{path::Path, io};

use runtime::prelude::*;
use ruby::{prelude::*, backtrace};

use runtime::classes;
use termcolor::{WriteColor, StandardStream, ColorChoice};

// This code just demonstrates that our native and non-native methods
// are working correctly. Neat!
static TEST_RUBY_CODE: &[u8] = include_bytes!("test.rb");

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let mut art = ruby::interpreter().expect("to be created properly");
    classes::demo::init(&mut art)?;

    let stderr = StandardStream::stderr(ColorChoice::Auto);

    // TODO: properly parse args into `ARGV`
    entrypoint(
        &mut art,
        stderr,
        vec![]
    )?;

    art.close();

    Ok(())
}

// TODO: properly load files 
// TODO: fix virtual filesystem?
fn entrypoint<W>(
    interp: &mut ruby::Artichoke,

    // known(unused): use in `execute_from_path` but that is currently wip
    #[allow(dead_code)] 
    #[allow(unused_variables)]
    error: W, 
    args: Vec<OsString>
) -> Result<(), Box<dyn std::error::Error>>
where
    W: io::Write + WriteColor
{
    // TODO: this

    let mut argv = Vec::new();

    // parse args into bytestring hahahfdsalsdfhj
    for arg in &args {
        let mut val = interp.try_convert_mut(arg.as_bytes())?;
        val.freeze(interp)?;
        argv.push(val);
    }

    let ruby_argv = interp.try_convert_mut(argv)?;
    interp.define_global_constant("ARGV", ruby_argv)?;
    interp.eval(TEST_RUBY_CODE)?;

    // execute_from_path(interp, error, Path::new("example.rb"))?;

    Ok(())
}

#[allow(dead_code)]
fn execute_from_path<W>(
    interp: &mut Artichoke,
    error: W,
    program_source_path: &Path
) -> Result<(), Box<dyn std::error::Error>>
where W: io::Write + WriteColor {
    if let Err(why) = interp.eval_file(program_source_path) {
        backtrace::format_cli_trace_into(error, interp, &why)?;
    }

    Ok(())
}