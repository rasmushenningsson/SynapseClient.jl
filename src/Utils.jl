module Utils


import SynapseClient: @utilfunction, @standalonefunction, synapsecall, synapseclient


@utilfunction as_url
@utilfunction datetime_to_iso
@utilfunction download_file
@utilfunction equal_paths
@utilfunction extract_filename
@utilfunction extract_prefix
@utilfunction extract_user_name
@utilfunction file_url_to_path
@utilfunction find_data_file_handle
@utilfunction format_time_interval
@utilfunction from_unix_epoch_time
@utilfunction from_unix_epoch_time_secs
@utilfunction get_properties
@utilfunction guess_file_name
@utilfunction id_of
@utilfunction is_in_path
@utilfunction is_same_base_url
@utilfunction is_synapse_id
@utilfunction is_url
@utilfunction iso_to_datetime
#@utilfunction itersubclasses
@utilfunction make_bogus_binary_file
@utilfunction make_bogus_data_file
@utilfunction md5_for_file
@utilfunction normalize_lines
@utilfunction normalize_path
@utilfunction normalize_whitespace
@utilfunction printTransferProgress
@utilfunction query_limit_and_offset
#@utilfunction threadsafe_generator
@utilfunction to_unix_epoch_time
@utilfunction to_unix_epoch_time_secs
@utilfunction touch
@utilfunction unique_filename

end
