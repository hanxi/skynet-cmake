/*
* Copyright 2023 The OpenSSL Project Authors. All Rights Reserved.
*
* Licensed under the Apache License 2.0 (the "License").  You may not use
* this file except in compliance with the License.  You can obtain a copy
* in the file LICENSE in the source distribution or at
* https://www.openssl.org/source/license.html
*/

#ifndef OSSL_INTERNAL_QUIC_LCIDM_H
# define OSSL_INTERNAL_QUIC_LCIDM_H
# pragma once

# include "internal/e_os.h"
# include "internal/time.h"
# include "internal/quic_types.h"
# include "internal/quic_wire.h"
# include "internal/quic_predef.h"

# ifndef OPENSSL_NO_QUIC

/*
 * QUIC Local Connection ID Manager
 * ================================
 *
 * This manages connection IDs for the RX side, which is to say that it issues
 * local CIDs (LCIDs) to a peer which that peer can then use to address us via a
 * packet DCID. This is as opposed to CID management for the TX side, which
 * determines which CIDs we use to transmit based on remote CIDs (RCIDs) the
 * peer sent to us.
 *
 * An opaque pointer can be associated with each LCID. Pointer identity
 * (equality) is used to distinguish distinct connections.
 *
 * LCIDs fall into three categories:
 *
 *   1. A client's Initial ODCID                       (1)
 *   2. Our local Initial SCID                         (1)
 *   3. A CID issued via a NEW_CONNECTION_ID frame     (n)
 *   4. A server's Retry SCID                          (0..1)
 *
 * (1) is enrolled using ossl_quic_lcidm_enrol_odcid() and retired by the time
 * of handshake completion at the latest. It is needed in case the first
 * response packet from a server is lost and the client keeps using its Initial
 * ODCID. There is never more than one of these, and no sequence number is
 * associated with this temporary LCID.
 *
 * (2) is created by a client when it begins connecting, or by a server when it
 * responds to a new connection request. In the latter case, it is generated by
 * the server as the preferred DCID for traffic directed towards it. A client
 * should switch to using this as a RCID as soon as it receives a valid packet
 * from the server. This LCID has a sequence number of 0.
 *
 * (3) is created when we issue a NEW_CONNECTION_ID frame. Arbitrarily many of
 * these can exist.
 *
 * (4) is a special case. When a server issues a retry it generates a new SCID
 * much as it does for (2). However since retries are supposed to be stateless,
 * we don't actually register it as an LCID. When the client subsequently
 * replies with an Initial packet with token in response to the Retry, the
 * server will handle this as a new connection attempt due to not recognising
 * the DCID, which is what we want anyway. (The Retry SCID is subsequently
 * validated as matching the new Initial ODCID via attestation in the encrypted
 * contents of the opaque retry token.) Thus, the LCIDM is not actually involved
 * at all here.
 *
 * Retirement is as follows:
 *
 * (1) is retired automatically when we know it won't be needed anymore. This is
 * when the handshake is completed at the latest, and could potentially be
 * earlier.
 *
 * Both (2) and (3) are retired normally via RETIRE_CONNECTION_ID frames, as it
 * has a sequence number of 0.
 *
 *
 * ODCID Peculiarities
 * -------------------
 *
 * Almost all LCIDs are issued by the receiver responsible for routing them,
 * which means that almost all LCIDs will have the same length (specified in
 * lcid_len below). The only exception to this is (1); the ODCID is the only
 * case where we recognise an LCID we didn't ourselves generate. Since an ODCID
 * is chosen by the peer, it can be any length and doesn't necessarily match the
 * length we use for LCIDs we generate ourselves.
 *
 * Since DCID decoding for short-header packets requires an implicitly known
 * DCID length, it logically follows that an ODCID can never be used in a 1-RTT
 * packet. This is fine as by the time the 1-RTT EL is reached the peer should
 * already have switched away from the ODCID to a CID we generated ourselves,
 * and if this has not happened we can consider that a protocol violation.
 *
 * In any case, this means that the LCIDM must necessarily support LCIDs of
 * different lengths, even if it always generates LCIDs of a given length.
 *
 * An ODCID has no sequence number associated with it. It is the only CID to
 * lack one.
 */

/*
 * Creates a new LCIDM. lcid_len is the length to use for LCIDs in bytes, which
 * may be zero.
 *
 * Returns NULL on failure.
 */
QUIC_LCIDM *ossl_quic_lcidm_new(OSSL_LIB_CTX *libctx, size_t lcid_len);

/* Frees a LCIDM. */
void ossl_quic_lcidm_free(QUIC_LCIDM *lcidm);

/* Gets the local CID length this LCIDM was configured to use. */
size_t ossl_quic_lcidm_get_lcid_len(const QUIC_LCIDM *lcidm);

/*
 * Determines the number of active LCIDs (i.e,. LCIDs which can be used for
 * reception) currently associated with the given opaque pointer.
 */
size_t ossl_quic_lcidm_get_num_active_lcid(const QUIC_LCIDM *lcidm,
                                           void *opaque);

/*
 * Enrol an Initial ODCID sent by the peer. This is the DCID in the first
 * Initial packet sent by a client. When we receive a client's first Initial
 * packet, we immediately respond with our own SCID (generated using
 * ossl_quic_lcidm_generate_initial) to tell the client to switch to using that,
 * so ideally the ODCID will only be used for a single packet. However since
 * that response might be lost, we also need to accept additional packets using
 * the ODCID and need to make sure they get routed to the same connection and
 * not interpreted as another new connection attempt. Thus before the CID
 * switchover is confirmed, we also have to handle incoming packets addressed to
 * the ODCID. This function is used to temporarily enroll the ODCID for a
 * connection. Such a LCID is considered to have a sequence number of
 * LCIDM_ODCID_SEQ_NUM internally for our purposes.
 *
 * Note that this is the *only* circumstance where we recognise an LCID we did
 * not generate ourselves, or allow an LCID with a different length to lcid_len.
 *
 * An ODCID MUST be at least 8 bytes in length (RFC 9000 s. 7.2).
 *
 * This function may only be called once for a given connection.
 * Returns 1 on success or 0 on failure.
 */
int ossl_quic_lcidm_enrol_odcid(QUIC_LCIDM *lcidm, void *opaque,
                                const QUIC_CONN_ID *initial_odcid);

/*
 * Retire a previously enrolled ODCID for a connection. This is generally done
 * when we know the peer won't be using it any more (when the handshake is
 * completed at the absolute latest, possibly earlier).
 *
 * Returns 1 if there was an enrolled ODCID which was retired and 0 if there was
 * not or on other failure.
 */
int ossl_quic_lcidm_retire_odcid(QUIC_LCIDM *lcidm, void *opaque);

/*
 * Create the first LCID for a given opaque pointer. The generated LCID is
 * written to *initial_lcid and associated with the given opaque pointer.
 *
 * After this function returns successfully, the caller can for example
 * register the new LCID with a DEMUX.
 *
 * May not be called more than once for a given opaque pointer value.
 */
int ossl_quic_lcidm_generate_initial(QUIC_LCIDM *lcidm,
                                     void *opaque,
                                     QUIC_CONN_ID *initial_lcid);

/*
 * Create a subsequent LCID for a given opaque pointer. The information needed
 * for a NEW_CONN_ID frame informing the peer of the new LCID, including the
 * LCID itself, is written to *ncid_frame.
 *
 * ncid_frame->stateless_reset is not initialised and the caller is responsible
 * for setting it.
 *
 * After this function returns successfully, the caller can for example
 * register the new LCID with a DEMUX and queue the NEW_CONN_ID frame.
 */
int ossl_quic_lcidm_generate(QUIC_LCIDM *lcidm,
                             void *opaque,
                             OSSL_QUIC_FRAME_NEW_CONN_ID *ncid_frame);

/*
 * Retire up to one LCID for a given opaque pointer value. Called repeatedly to
 * handle a RETIRE_CONN_ID frame.
 *
 * If containing_pkt_dcid is non-NULL, this function enforces the requirement
 * that a CID not be retired by a packet using that CID as the DCID. If
 * containing_pkt_dcid is NULL, this check is skipped.
 *
 * If a LCID is retired as a result of a call to this function, the LCID which
 * was retired is written to *retired_lcid, the sequence number of the LCID is
 * written to *retired_seq_num and *did_retire is set to 1. Otherwise,
 * *did_retire is set to 0. This enables a caller to e.g. unregister the LCID
 * from a DEMUX. A caller should call this function repeatedly until the
 * function returns with *did_retire set to 0.
 *
 * This call is likely to cause the value returned by
 * ossl_quic_lcidm_get_num_active_lcid() to go down. A caller may wish to call
 * ossl_quic_lcidm_generate() repeatedly to bring the number of active LCIDs
 * back up to some threshold in response after calling this function.
 *
 * Returns 1 on success and 0 on failure. If arguments are valid but zero LCIDs
 * are retired, this is considered a success condition.
 */
int ossl_quic_lcidm_retire(QUIC_LCIDM *lcidm,
                           void *opaque,
                           uint64_t retire_prior_to,
                           const QUIC_CONN_ID *containing_pkt_dcid,
                           QUIC_CONN_ID *retired_lcid,
                           uint64_t *retired_seq_num,
                           int *did_retire);

/*
 * Cull all LCIDM state relating to a given opaque pointer value. This is useful
 * if connection state is spontaneously freed. The caller is responsible for
 * e.g. DEMUX state updates.
 */
int ossl_quic_lcidm_cull(QUIC_LCIDM *lcidm, void *opaque);

/*
 * Lookup a LCID. If the LCID is found, writes the associated opaque pointer to
 * *opaque and the associated sequence number to *seq_num. Returns 1 on success
 * and 0 if an entry is not found. An output argument may be set to NULL if its
 * value is not required.
 *
 * If the LCID is for an Initial ODCID, *seq_num is set to
 * LCIDM_ODCID_SEQ_NUM.
 */
#define LCIDM_ODCID_SEQ_NUM     UINT64_MAX

int ossl_quic_lcidm_lookup(QUIC_LCIDM *lcidm,
                           const QUIC_CONN_ID *lcid,
                           uint64_t *seq_num,
                           void **opaque);

/*
 * Debug call to manually remove a specific LCID. Should not be needed in normal
 * usage. Returns 1 if the LCID was successfully found and removed and 0
 * otherwise.
 */
int ossl_quic_lcidm_debug_remove(QUIC_LCIDM *lcidm,
                                 const QUIC_CONN_ID *lcid);

/*
 * Debug call to manually add a numbered LCID with a specific CID value and
 * sequence number. Should not be needed in normal usage. Returns 1 on success
 * and 0 on failure.
 */
int ossl_quic_lcidm_debug_add(QUIC_LCIDM *lcidm, void *opaque,
                              const QUIC_CONN_ID *lcid,
                              uint64_t seq_num);

# endif

#endif
