use std::ffi::{CStr, CString};
use std::os::raw::{c_char, c_int, c_longlong};
use std::path::Path;
use rayon::prelude::*;

#[cfg(windows)]
use winapi::um::winbase::CopyFileExW;
#[cfg(windows)]
use winapi::um::winnt::{HANDLE, LARGE_INTEGER};
#[cfg(windows)]
use std::os::windows::ffi::OsStrExt;

#[cfg(not(windows))]
use std::fs::File;
#[cfg(not(windows))]
use std::io::{Read, Write};

/// Callback type for progress reporting: (bytes_transferred)
type ProgressCallback = extern "C" fn(c_longlong);

#[repr(C)]
pub struct CopyItem {
    pub src: *const c_char,
    pub dst: *const c_char,
}

// Safety: CopyItem contains raw pointers, which are not Send/Sync by default.
// However, since we are only reading from these pointers within the batch copy
// and the strings they point to are expected to live for the duration of the call,
// we can safely mark it as Send+Sync for parallel processing.
unsafe impl Send for CopyItem {}
unsafe impl Sync for CopyItem {}

#[no_mangle]
pub extern "C" fn copy_file_native(
    src: *const c_char,
    dst: *const c_char,
    callback: Option<ProgressCallback>,
) -> c_int {
    let src_str = match unsafe { CStr::from_ptr(src).to_str() } {
        Ok(s) => s,
        Err(_) => return -1,
    };
    let dst_str = match unsafe { CStr::from_ptr(dst).to_str() } {
        Ok(s) => s,
        Err(_) => return -2,
    };

    #[cfg(windows)]
    {
        return copy_file_windows(src_str, dst_str, callback);
    }

    #[cfg(not(windows))]
    {
        return copy_file_linux(src_str, dst_str, callback);
    }
}

#[cfg(windows)]
fn copy_file_windows(src: &str, dst: &str, callback: Option<ProgressCallback>) -> c_int {
    use std::ptr;
    use winapi::shared::minwindef::{BOOL, DWORD, LPVOID, FALSE};
    use winapi::um::winbase::PROGRESS_CONTINUE;

    let src_wide: Vec<u16> = Path::new(src).as_os_str().encode_wide().chain(Some(0)).collect();
    let dst_wide: Vec<u16> = Path::new(dst).as_os_str().encode_wide().chain(Some(0)).collect();

    unsafe extern "system" fn progress_routine(
        _total_file_size: LARGE_INTEGER,
        total_bytes_transferred: LARGE_INTEGER,
        _stream_size: LARGE_INTEGER,
        _stream_bytes_transferred: LARGE_INTEGER,
        _dw_stream_number: DWORD,
        _dw_callback_reason: DWORD,
        _h_source_file: HANDLE,
        _h_destination_file: HANDLE,
        lp_data: LPVOID,
    ) -> DWORD {
        if !lp_data.is_null() {
            let cb: ProgressCallback = std::mem::transmute(lp_data);
            // LARGE_INTEGER is a union, we want QuadPart
            cb(*total_bytes_transferred.QuadPart() as c_longlong);
        }
        PROGRESS_CONTINUE
    }

    let cancel: BOOL = FALSE;
    let success = unsafe {
        CopyFileExW(
            src_wide.as_ptr(),
            dst_wide.as_ptr(),
            if callback.is_some() { Some(progress_routine) } else { None },
            callback.map(|cb| cb as LPVOID).unwrap_or(ptr::null_mut()),
            &cancel as *const _ as *mut _,
            0, // flags
        )
    };

    if success != 0 { 0 } else { -3 }
}

#[cfg(not(windows))]
fn copy_file_linux(src: &str, dst: &str, callback: Option<ProgressCallback>) -> c_int {
    let mut source = match File::open(src) {
        Ok(f) => f,
        Err(_) => return -4,
    };
    let mut dest = match File::create(dst) {
        Ok(f) => f,
        Err(_) => return -5,
    };

    let mut buffer = vec![0u8; 8 * 1024 * 1024]; // 8MB buffer
    let mut total_written = 0;

    loop {
        let bytes_read = match source.read(&mut buffer) {
            Ok(0) => break,
            Ok(n) => n,
            Err(_) => return -6,
        };

        if let Err(_) = dest.write_all(&buffer[..bytes_read]) {
            return -7;
        }

        total_written += bytes_read as i64;
        if let Some(cb) = callback {
            cb(total_written as c_longlong);
        }
    }

    0
}

#[no_mangle]
pub extern "C" fn copy_batch_native(
    items: *const CopyItem,
    count: usize,
    _concurrency: usize,
    callback: Option<ProgressCallback>,
) -> c_int {
    let items_slice = unsafe { std::slice::from_raw_parts(items, count) };

    let results: Vec<c_int> = items_slice.par_iter().map(|item| {
        copy_file_native(item.src, item.dst, None)
    }).collect();

    // Just report total items completed as a proxy for batch progress for now
    if let Some(cb) = callback {
        cb(count as c_longlong);
    }

    if results.iter().all(|&r| r == 0) { 0 } else { -8 }
}

#[no_mangle]
pub extern "C" fn free_string(s: *mut c_char) {
    unsafe {
        if s.is_null() { return; }
        let _ = CString::from_raw(s);
    }
}
