defmodule ExTauri.Tauri.RustMainSourceCode do

	require Logger

	# Override main.rs to set proper startup sequence
	def override(release_name) do
	  path = [File.cwd!(), "src-tauri", "src", "main.rs"] |> Path.join()

	  Logger.warning("Overriding Rust source code for main.rs at: " <> path)

	  code = build_main_src_code(release_name)

	  path
	  |> File.write!(code)
	end

	defp build_main_src_code(release_name) do
	  host = Application.get_env(:ex_tauri, :host) || raise "Expected :host to be configured"
	  port = Application.get_env(:ex_tauri, :port) || raise "Expected :port to be configured"

	  """
	  // Prevents additional console window on Windows in release, DO NOT REMOVE!!
	  #![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]
	  use tauri::api::process::{Command, CommandEvent};

	  fn main() {
	  		let _ = fix_path_env::fix();

	      tauri::Builder::default()
	          .setup(|_app| {
	              start_server();
	              check_server_started();
	              Ok(())
	          })
	          .run(tauri::generate_context!())
	          .expect("error while running tauri application");
	  }
	  fn start_server() {
	      tauri::async_runtime::spawn(async move {
	          let (mut rx, mut _child) = Command::new_sidecar("#{release_name}")
	              .expect("failed to setup `#{release_name}` sidecar")
	              .spawn()
	              .expect("Failed to spawn sidecar for #{release_name}");

	          while let Some(event) = rx.recv().await {
	              if let CommandEvent::Stdout(line) = event {
	                  println!("{}", line);
	              }
	          }
	      });
	  }

	  fn check_server_started() {
	      let sleep_interval = std::time::Duration::from_millis(200);
	      let host = "#{host}".to_string();
	      let port = "#{port}".to_string();
	      let addr = format!("{}:{}", host, port);
	      println!(
	          "Waiting for your phoenix dev server to start on {}",
	          addr
	      );
	      loop {
	          println!(".");
	          if std::net::TcpStream::connect(addr.clone()).is_ok() {
	            break;
	          }
	          std::thread::sleep(sleep_interval);
	      }
	  }

	  """
	end
end
