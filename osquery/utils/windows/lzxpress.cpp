/**
 * Copyright (c) 2014-present, The osquery authors
 *
 * This source code is licensed as defined by the LICENSE file found in the
 * root directory of this source tree.
 *
 * SPDX-License-Identifier: (Apache-2.0 OR GPL-2.0-only)
 */

#include <osquery/logger/logger.h>
#include <osquery/utils/expected/expected.h>
#include <osquery/utils/windows/lzxpress.h>

#include <boost/algorithm/hex.hpp>
#include <boost/algorithm/string.hpp>

namespace osquery {
ExpectedDecompressData decompressLZxpress(std::vector<char> prefetch_data,
                                          unsigned long size) {
  static HMODULE hDLL =
      LoadLibraryExW(L"ntdll.dll", NULL, LOAD_LIBRARY_SEARCH_SYSTEM32);
  if (hDLL == nullptr) {
    LOG(ERROR) << "Failed to load ntdll.dll";
    return ExpectedDecompressData::failure(ConversionError::InvalidArgument,
                                           "Failed to load ntdll.dll");
  }

  typedef HRESULT(WINAPI * pRtlDecompressBufferEx)(
      _In_ unsigned short format,
      _Out_ unsigned char* uncompressedBuffer,
      _In_ unsigned long uncompressedSize,
      _In_ unsigned char* data,
      _In_ unsigned long dataSize,
      _Out_ unsigned long* finalSize,
      _In_ PVOID workspace);

  typedef HRESULT(WINAPI * pRtlGetCompressionWorkSpaceSize)(
      _In_ unsigned short format,
      _Out_ unsigned long* bufferWorkSpaceSize,
      _Out_ unsigned long* fragmentWorkSpaceSize);

  pRtlDecompressBufferEx RtlDecompressBufferEx;
  pRtlGetCompressionWorkSpaceSize RtlGetCompressionWorkSpaceSize;
  RtlGetCompressionWorkSpaceSize =
      reinterpret_cast<pRtlGetCompressionWorkSpaceSize>(
          GetProcAddress(hDLL, "RtlGetCompressionWorkSpaceSize"));
  if (RtlGetCompressionWorkSpaceSize == nullptr) {
    LOG(ERROR) << "Failed to load function RtlGetCompressionWorkSpaceSize";
    return ExpectedDecompressData::failure(
        ConversionError::InvalidArgument,
        "Failed to load function RtlGetCompressionWorkSpaceSize");
  }
  RtlDecompressBufferEx = reinterpret_cast<pRtlDecompressBufferEx>(
      GetProcAddress(hDLL, "RtlDecompressBufferEx"));

  // Check for decompression function, only exists on Win8+
  if (RtlDecompressBufferEx == nullptr) {
    LOG(ERROR) << "Failed to load function RtlDecompressBufferEx";
    return ExpectedDecompressData::failure(
        ConversionError::InvalidArgument,
        "Failed to load function RtlDecompressBufferEx");
  }
  unsigned long bufferWorkSpaceSize = 0ul;
  unsigned long fragmentWorkSpaceSize = 0ul;
  auto results = RtlGetCompressionWorkSpaceSize(COMPRESSION_FORMAT_XPRESS_HUFF,
                                                &bufferWorkSpaceSize,
                                                &fragmentWorkSpaceSize);
  if (results != 0) {
    LOG(ERROR) << "Failed to set compression workspace size";
    return ExpectedDecompressData::failure(
        ConversionError::InvalidArgument,
        "Failed to set compression workspace size");
  }
  unsigned char* compressed_data = new unsigned char[prefetch_data.size() - 8];

  // Substract header size from compressed data size
  for (int i = 8; i < prefetch_data.size(); i++) {
    compressed_data[i - 8] = prefetch_data[i];
  }
  unsigned char* output_buffer = new unsigned char[size];

  unsigned long buffer_size =
      static_cast<unsigned long>(prefetch_data.size() - 8);
  unsigned long final_size = 0ul;
  PVOID fragment_workspace = new unsigned char*[fragmentWorkSpaceSize];
  auto decom_results = RtlDecompressBufferEx(COMPRESSION_FORMAT_XPRESS_HUFF,
                                             output_buffer,
                                             size,
                                             compressed_data,
                                             buffer_size,
                                             &final_size,
                                             fragment_workspace);
  if (decom_results != 0) {
    LOG(ERROR) << "Failed to decompress data";
    return ExpectedDecompressData::failure(ConversionError::InvalidArgument,
                                           "Failed to decompress data");
  }
  std::stringstream ss;
  for (unsigned long i = 0; i < size; i++) {
    std::stringstream value;
    value << std::setfill('0') << std::setw(2);
    value << std::hex << std::uppercase << static_cast<int>((output_buffer[i]));
    ss << value.str();
  }
  std::string decompress_hex = ss.str();
  free(compressed_data);
  free(fragment_workspace);
  free(output_buffer);

  return ExpectedDecompressData::success(decompress_hex);
}

} // namespace osquery
