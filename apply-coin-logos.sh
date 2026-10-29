#!/usr/bin/env bash
# Mbuni CEX — real cryptocurrency logos. Run from the project root: bash apply-coin-logos.sh
set -euo pipefail
[ -f package.json ] && [ -d src/components/opencex ] || { echo "Run from the project root"; exit 1; }
w(){ mkdir -p "$(dirname "$1")"; [ -f "$1" ] && [ ! -f "$1.orig" ] && cp "$1" "$1.orig"; cat > "$1"; echo "  wrote $1"; }

w 'public/crypto/LICENSES.md' <<'MBUNI_LOGO_EOF'
Creative Commons Legal Code

CC0 1.0 Universal

    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
    LEGAL SERVICES. DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN
    ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
    INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
    REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS
    PROVIDED HEREUNDER, AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM
    THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED
    HEREUNDER.

Statement of Purpose

The laws of most jurisdictions throughout the world automatically confer
exclusive Copyright and Related Rights (defined below) upon the creator
and subsequent owner(s) (each and all, an "owner") of an original work of
authorship and/or a database (each, a "Work").

Certain owners wish to permanently relinquish those rights to a Work for
the purpose of contributing to a commons of creative, cultural and
scientific works ("Commons") that the public can reliably and without fear
of later claims of infringement build upon, modify, incorporate in other
works, reuse and redistribute as freely as possible in any form whatsoever
and for any purposes, including without limitation commercial purposes.
These owners may contribute to the Commons to promote the ideal of a free
culture and the further production of creative, cultural and scientific
works, or to gain reputation or greater distribution for their Work in
part through the use and efforts of others.

For these and/or other purposes and motivations, and without any
expectation of additional consideration or compensation, the person
associating CC0 with a Work (the "Affirmer"), to the extent that he or she
is an owner of Copyright and Related Rights in the Work, voluntarily
elects to apply CC0 to the Work and publicly distribute the Work under its
terms, with knowledge of his or her Copyright and Related Rights in the
Work and the meaning and intended legal effect of CC0 on those rights.

1. Copyright and Related Rights. A Work made available under CC0 may be
protected by copyright and related or neighboring rights ("Copyright and
Related Rights"). Copyright and Related Rights include, but are not
limited to, the following:

  i. the right to reproduce, adapt, distribute, perform, display,
     communicate, and translate a Work;
 ii. moral rights retained by the original author(s) and/or performer(s);
iii. publicity and privacy rights pertaining to a person's image or
     likeness depicted in a Work;
 iv. rights protecting against unfair competition in regards to a Work,
     subject to the limitations in paragraph 4(a), below;
  v. rights protecting the extraction, dissemination, use and reuse of data
     in a Work;
 vi. database rights (such as those arising under Directive 96/9/EC of the
     European Parliament and of the Council of 11 March 1996 on the legal
     protection of databases, and under any national implementation
     thereof, including any amended or successor version of such
     directive); and
vii. other similar, equivalent or corresponding rights throughout the
     world based on applicable law or treaty, and any national
     implementations thereof.

2. Waiver. To the greatest extent permitted by, but not in contravention
of, applicable law, Affirmer hereby overtly, fully, permanently,
irrevocably and unconditionally waives, abandons, and surrenders all of
Affirmer's Copyright and Related Rights and associated claims and causes
of action, whether now known or unknown (including existing as well as
future claims and causes of action), in the Work (i) in all territories
worldwide, (ii) for the maximum duration provided by applicable law or
treaty (including future time extensions), (iii) in any current or future
medium and for any number of copies, and (iv) for any purpose whatsoever,
including without limitation commercial, advertising or promotional
purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each
member of the public at large and to the detriment of Affirmer's heirs and
successors, fully intending that such Waiver shall not be subject to
revocation, rescission, cancellation, termination, or any other legal or
equitable action to disrupt the quiet enjoyment of the Work by the public
as contemplated by Affirmer's express Statement of Purpose.

3. Public License Fallback. Should any part of the Waiver for any reason
be judged legally invalid or ineffective under applicable law, then the
Waiver shall be preserved to the maximum extent permitted taking into
account Affirmer's express Statement of Purpose. In addition, to the
extent the Waiver is so judged Affirmer hereby grants to each affected
person a royalty-free, non transferable, non sublicensable, non exclusive,
irrevocable and unconditional license to exercise Affirmer's Copyright and
Related Rights in the Work (i) in all territories worldwide, (ii) for the
maximum duration provided by applicable law or treaty (including future
time extensions), (iii) in any current or future medium and for any number
of copies, and (iv) for any purpose whatsoever, including without
limitation commercial, advertising or promotional purposes (the
"License"). The License shall be deemed effective as of the date CC0 was
applied by Affirmer to the Work. Should any part of the License for any
reason be judged legally invalid or ineffective under applicable law, such
partial invalidity or ineffectiveness shall not invalidate the remainder
of the License, and in such case Affirmer hereby affirms that he or she
will not (i) exercise any of his or her remaining Copyright and Related
Rights in the Work or (ii) assert any associated claims and causes of
action with respect to the Work, in either case contrary to Affirmer's
express Statement of Purpose.

4. Limitations and Disclaimers.

 a. No trademark or patent rights held by Affirmer are waived, abandoned,
    surrendered, licensed or otherwise affected by this document.
 b. Affirmer offers the Work as-is and makes no representations or
    warranties of any kind concerning the Work, express, implied,
    statutory or otherwise, including without limitation warranties of
    title, merchantability, fitness for a particular purpose, non
    infringement, or the absence of latent or other defects, accuracy, or
    the present or absence of errors, whether or not discoverable, all to
    the greatest extent permissible under applicable law.
 c. Affirmer disclaims responsibility for clearing rights of other persons
    that may apply to the Work or any use thereof, including without
    limitation any person's Copyright and Related Rights in the Work.
    Further, Affirmer disclaims responsibility for obtaining any necessary
    consents, permissions or other rights required for any use of the
    Work.
 d. Affirmer understands and acknowledges that Creative Commons is not a
    party to this document and has no duty or obligation with respect to
    this CC0 or use of the Work.


ARB, OP, TON: @web3icons/core (MIT). Others: cryptocurrency-icons (CC0-1.0). Logos are trademarks of their respective owners.
MBUNI_LOGO_EOF
w 'public/crypto/ada.svg' <<'MBUNI_LOGO_EOF'
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><defs><filter x="-7.5%" y="-6%" width="115.5%" height="117.2%" filterUnits="objectBoundingBox" id="a"><feOffset dy=".5" in="SourceAlpha" result="shadowOffsetOuter1"/><feGaussianBlur stdDeviation=".5" in="shadowOffsetOuter1" result="shadowBlurOuter1"/><feColorMatrix values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.204257246 0" in="shadowBlurOuter1"/></filter><path d="M15.725 6.06c.479-.247 1.064.324.81.795-.149.384-.71.486-.996.193-.303-.28-.204-.836.186-.989zm-5.155.546c.291-.118.66.144.63.457.03.338-.39.588-.687.427-.393-.15-.348-.778.057-.884zm10.558.893c-.455-.054-.527-.758-.09-.9.34-.162.652.143.702.46-.072.27-.302.518-.612.44zm-9.385 1.265c.487-.303 1.181.148 1.106.705-.025.561-.783.887-1.211.507-.414-.298-.351-.982.105-1.212zm7.43.322c.217-.55 1.097-.568 1.344-.032.245.417-.056.934-.491 1.076-.577.106-1.124-.508-.853-1.044zm-4.069 1.013c-.005-.474.433-.826.89-.859.304.06.634.187.764.488.243.416.027.987-.41 1.178-.2.11-.438.069-.656.056-.333-.16-.614-.477-.588-.863zm-7.666.69c.445-.27 1.045.22.876.696-.092.411-.654.578-.975.316-.343-.246-.289-.837.1-1.013zm16.462-.002c.377-.288 1 .043.954.511.026.427-.513.75-.887.53-.412-.183-.455-.807-.067-1.04zm-6.64.851c.622-.22 1.362.043 1.716.59.468.667.22 1.683-.507 2.066-.752.453-1.851.07-2.13-.758-.315-.74.145-1.666.92-1.898zm-3.653.073c.69-.32 1.619-.052 1.952.642.392.676.089 1.617-.612 1.966-.702.393-1.693.095-2.032-.63-.381-.702-.043-1.655.692-1.978zM9.95 12.94c.053-.437.472-.722.895-.752a.98.98 0 01.87.857c-.03.45-.383.888-.867.886-.533.045-1-.477-.898-.991zm10.802-.656c.547-.313 1.306.142 1.282.76.037.655-.803 1.116-1.347.732-.566-.32-.522-1.22.065-1.492zm-8.63 2.307c.638-.173 1.37.123 1.683.701.343.582.203 1.39-.33 1.818-.685.626-1.946.374-2.31-.48-.419-.783.09-1.833.956-2.04zm6.927-.003c.621-.175 1.351.06 1.685.617.442.637.231 1.588-.426 1.998-.69.477-1.756.227-2.136-.519-.46-.771.003-1.861.877-2.096zm-11.04.726c.552-.205 1.164.394.94.933-.136.49-.839.672-1.202.31-.425-.34-.268-1.095.262-1.243zm14.969.782a.836.836 0 01.788-.874c.378.06.746.36.716.765.035.535-.62.898-1.084.647-.217-.109-.328-.328-.42-.538zM5.294 15.58c.332-.143.743.14.667.503-.018.411-.635.57-.861.226-.2-.239-.08-.606.194-.73zm20.949-.009c.234-.163.61-.046.702.223.157.294-.131.696-.467.647-.472.042-.624-.665-.235-.87zm-12.317 1.973c.874-.223 1.814.494 1.82 1.38.056.895-.87 1.688-1.764 1.482-.692-.11-1.235-.766-1.212-1.453-.002-.658.502-1.27 1.156-1.409zm3.462-.001c.887-.244 1.855.486 1.841 1.392.047.878-.85 1.645-1.726 1.47-.825-.104-1.433-.995-1.203-1.783.116-.524.562-.95 1.088-1.08zm-6.676.545c.614-.103 1.19.57.941 1.144-.182.612-1.086.777-1.486.278-.468-.48-.118-1.356.545-1.422zm10.154.027c.548-.226 1.22.24 1.178.825.022.643-.808 1.087-1.343.711-.607-.337-.496-1.33.165-1.536zm2.838 2.8c-.214-.393.175-.914.62-.841.22-.004.375.167.516.311.029.233.078.511-.119.69-.267.333-.872.238-1.017-.16zm-16.268-.732c.415-.271 1.012.134.918.61-.05.423-.59.664-.945.424-.382-.217-.368-.836.027-1.034zm8.193.883c.543-.235 1.235.23 1.183.818.04.65-.815 1.1-1.346.71-.59-.335-.491-1.321.163-1.528zm-3.794.871c.462-.239 1.082.174 1.04.684.014.418-.4.774-.82.712-.347-.007-.573-.314-.685-.605.006-.317.139-.67.465-.79zm7.686.008c.476-.29 1.152.126 1.107.67.012.57-.752.934-1.195.56-.428-.293-.376-.997.088-1.23zm1.337 3.25c-.212-.314.037-.693.38-.765.277.055.57.26.511.574-.04.427-.674.557-.891.192zm-10.611-.273c.084-.25.288-.497.587-.432.435.03.564.676.183.875-.342.227-.74-.084-.77-.443zm5.12.287c.083-.37.568-.549.888-.353.212.09.274.322.328.52a8.822 8.822 0 00-.08.31c-.131.152-.3.305-.518.3-.405.047-.771-.404-.619-.777z" id="b"/></defs><g fill="none"><circle cx="16" cy="16" r="16" fill="#0D1E30"/><use fill="#000" filter="url(#a)" xlink:href="#b"/><use fill="#FFF" xlink:href="#b"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/arb.svg' <<'MBUNI_LOGO_EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" class="web3icons">
    <g clip-path="url(#ARB__a)">
        <path fill="#000" d="M24 0H0v24h24z"/>
        <path fill="#fff" fill-rule="evenodd" d="M20 6.58a2.58 2.58 0 0 1-2.622 2.581c.026.165.041.34.041.516v7.226A3.097 3.097 0 0 1 14.323 20H7.097A3.097 3.097 0 0 1 4 16.903V9.677a3.097 3.097 0 0 1 3.097-3.096h7.226c.175 0 .35.015.516.04v-.04a2.58 2.58 0 0 1 5.161 0m-5.094.584a2.6 2.6 0 0 0-.583-.067H7.097a2.58 2.58 0 0 0-2.58 2.58v7.226a2.58 2.58 0 0 0 2.58 2.58h7.226a2.58 2.58 0 0 0 2.58-2.58V9.677c0-.2-.02-.397-.067-.583a2.58 2.58 0 0 1-1.93-1.93m1.997-2.132v1.033h-1.032v1.032h1.032v1.032h1.032V7.097h1.033V6.065h-1.033V5.032zM6.323 16.903H4.774l2.323-7.226h1.548l2.065 5.678V9.677h3.096c.687 0 2.065.413 2.065 2.065s-.862 2.064-1.29 2.064l1.806 3.097h-1.806l-1.549-3.096h-.774v3.096H9.936l-.62-1.548H6.787zm.774-2.58h1.806l-1.032-2.581zm6.451-1.549h-1.29V10.71h1.29c.258 0 .775.206.775 1.032s-.517 1.032-.775 1.032m-3.354 5.657v-.077q-.001-.023.02-.021h.078v-.785h-.078c-.01 0-.02-.005-.02-.02v-.078c0-.015.01-.03.02-.03h.325a.44.44 0 0 1 .248.061.2.2 0 0 1 .093.18.22.22 0 0 1-.052.145.3.3 0 0 1-.113.093c.072.01.129.042.165.083a.25.25 0 0 1 .057.17.26.26 0 0 1-.088.207.4.4 0 0 1-.237.087l-.197.006h-.2q-.022 0-.021-.021m.258-.454v.361h.062q.125 0 .196-.046c.046-.026.067-.078.067-.145q.002-.17-.222-.17zm0-.434v.31h.051q.211 0 .212-.155.001-.093-.052-.124a.26.26 0 0 0-.144-.03zm.836.005v.785h.077c.01 0 .02.005.02.02v.078c0 .015-.01.02-.02.02h-.31q-.024.001-.025-.02v-.077c0-.016.01-.021.02-.021h.078v-.785h-.078c-.01 0-.02-.005-.02-.02v-.078c0-.015.01-.03.02-.03h.31c.016 0 .026.015.026.03v.078c0 .015-.01.02-.02.02zm.774.904q.021 0 .02-.021v-.077q.001-.023-.02-.021h-.119v-.785h.196l-.01.12q-.001.021.02.02h.088q.022.001.021-.02v-.218c0-.015-.005-.03-.02-.03h-.754c-.01 0-.02.015-.02.03v.217c0 .016.01.02.02.02h.088q.021.002.02-.02l-.005-.119h.191v.785h-.119c-.01 0-.02.005-.02.02v.078c0 .015.01.02.02.02z" clip-rule="evenodd"/>
    </g>
    <defs>
        <clipPath id="ARB__a">
            <path fill="#fff" d="M0 0h24v24H0z"/>
        </clipPath>
    </defs>
</svg>
MBUNI_LOGO_EOF
w 'public/crypto/avax.svg' <<'MBUNI_LOGO_EOF'
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg"><g fill="none" fill-rule="evenodd"><circle fill="#E84142" fill-rule="nonzero" cx="16" cy="16" r="16"/><path d="M11.518 22.75H8.49c-.636 0-.95 0-1.142-.123A.77.77 0 017 22.025c-.012-.226.145-.503.46-1.055l7.472-13.193c.318-.56.48-.84.682-.944a.77.77 0 01.698 0c.203.104.364.384.682.944l1.536 2.686.008.014c.343.6.517.906.593 1.226a2.26 2.26 0 010 1.066c-.076.323-.249.63-.597 1.24l-3.926 6.95-.01.017c-.346.606-.52.913-.764 1.145a2.284 2.284 0 01-.93.54c-.319.089-.675.089-1.387.089zm7.643 0h4.336c.64 0 .962 0 1.154-.126a.768.768 0 00.348-.607c.011-.219-.142-.484-.443-1.005l-.032-.054-2.172-3.722-.025-.042c-.305-.517-.46-.778-.657-.879a.762.762 0 00-.693 0c-.2.104-.36.377-.678.925l-2.165 3.722-.007.013c-.317.548-.476.821-.464 1.046a.777.777 0 00.348.606c.188.123.51.123 1.15.123z" fill="#FFF"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/bnb.svg' <<'MBUNI_LOGO_EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><g fill="none"><circle cx="16" cy="16" r="16" fill="#F3BA2F"/><path fill="#FFF" d="M12.116 14.404L16 10.52l3.886 3.886 2.26-2.26L16 6l-6.144 6.144 2.26 2.26zM6 16l2.26-2.26L10.52 16l-2.26 2.26L6 16zm6.116 1.596L16 21.48l3.886-3.886 2.26 2.259L16 26l-6.144-6.144-.003-.003 2.263-2.257zM21.48 16l2.26-2.26L26 16l-2.26 2.26L21.48 16zm-3.188-.002h.002V16L16 18.294l-2.291-2.29-.004-.004.004-.003.401-.402.195-.195L16 13.706l2.293 2.293z"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/btc.svg' <<'MBUNI_LOGO_EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><g fill="none" fill-rule="evenodd"><circle cx="16" cy="16" r="16" fill="#F7931A"/><path fill="#FFF" fill-rule="nonzero" d="M23.189 14.02c.314-2.096-1.283-3.223-3.465-3.975l.708-2.84-1.728-.43-.69 2.765c-.454-.114-.92-.22-1.385-.326l.695-2.783L15.596 6l-.708 2.839c-.376-.086-.746-.17-1.104-.26l.002-.009-2.384-.595-.46 1.846s1.283.294 1.256.312c.7.175.826.638.805 1.006l-.806 3.235c.048.012.11.03.18.057l-.183-.045-1.13 4.532c-.086.212-.303.531-.793.41.018.025-1.256-.313-1.256-.313l-.858 1.978 2.25.561c.418.105.828.215 1.231.318l-.715 2.872 1.727.43.708-2.84c.472.127.93.245 1.378.357l-.706 2.828 1.728.43.715-2.866c2.948.558 5.164.333 6.097-2.333.752-2.146-.037-3.385-1.588-4.192 1.13-.26 1.98-1.003 2.207-2.538zm-3.95 5.538c-.533 2.147-4.148.986-5.32.695l.95-3.805c1.172.293 4.929.872 4.37 3.11zm.535-5.569c-.487 1.953-3.495.96-4.47.717l.86-3.45c.975.243 4.118.696 3.61 2.733z"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/doge.svg' <<'MBUNI_LOGO_EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><g fill="none" fill-rule="evenodd"><circle cx="16" cy="16" r="16" fill="#C3A634"/><path fill="#FFF" d="M13.248 14.61h4.314v2.286h-4.314v4.818h2.721c1.077 0 1.958-.145 2.644-.437.686-.291 1.224-.694 1.615-1.21a4.4 4.4 0 00.796-1.815 11.4 11.4 0 00.21-2.252 11.4 11.4 0 00-.21-2.252 4.396 4.396 0 00-.796-1.815c-.391-.516-.93-.919-1.615-1.21-.686-.292-1.567-.437-2.644-.437h-2.721v4.325zm-2.766 2.286H9v-2.285h1.482V8h6.549c1.21 0 2.257.21 3.142.627.885.419 1.607.99 2.168 1.715.56.724.977 1.572 1.25 2.543.273.971.409 2.01.409 3.115a11.47 11.47 0 01-.41 3.115c-.272.97-.689 1.819-1.25 2.543-.56.725-1.282 1.296-2.167 1.715-.885.418-1.933.627-3.142.627h-6.549v-7.104z"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/eth.svg' <<'MBUNI_LOGO_EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><g fill="none" fill-rule="evenodd"><circle cx="16" cy="16" r="16" fill="#627EEA"/><g fill="#FFF" fill-rule="nonzero"><path fill-opacity=".602" d="M16.498 4v8.87l7.497 3.35z"/><path d="M16.498 4L9 16.22l7.498-3.35z"/><path fill-opacity=".602" d="M16.498 21.968v6.027L24 17.616z"/><path d="M16.498 27.995v-6.028L9 17.616z"/><path fill-opacity=".2" d="M16.498 20.573l7.497-4.353-7.497-3.348z"/><path fill-opacity=".602" d="M9 16.22l7.498 4.353v-7.701z"/></g></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/link.svg' <<'MBUNI_LOGO_EOF'
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg"><g fill="none"><circle fill="#2A5ADA" cx="16" cy="16" r="16"/><path d="M16 6l-1.799 1.055L9.3 9.945 7.5 11v10l1.799 1.055 4.947 2.89L16.045 26l1.799-1.055 4.857-2.89L24.5 21V11l-1.799-1.055-4.902-2.89L16 6zm-4.902 12.89v-5.78L16 10.22l4.902 2.89v5.78L16 21.78l-4.902-2.89z" fill="#FFF"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/matic.svg' <<'MBUNI_LOGO_EOF'
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg"><g fill="none"><circle fill="#6F41D8" cx="16" cy="16" r="16"/><path d="M21.092 12.693c-.369-.215-.848-.215-1.254 0l-2.879 1.654-1.955 1.078-2.879 1.653c-.369.216-.848.216-1.254 0l-2.288-1.294c-.369-.215-.627-.61-.627-1.042V12.19c0-.431.221-.826.627-1.042l2.25-1.258c.37-.216.85-.216 1.256 0l2.25 1.258c.37.216.628.611.628 1.042v1.654l1.955-1.115v-1.653a1.16 1.16 0 00-.627-1.042l-4.17-2.372c-.369-.216-.848-.216-1.254 0l-4.244 2.372A1.16 1.16 0 006 11.076v4.78c0 .432.221.827.627 1.043l4.244 2.372c.369.215.849.215 1.254 0l2.879-1.618 1.955-1.114 2.879-1.617c.369-.216.848-.216 1.254 0l2.251 1.258c.37.215.627.61.627 1.042v2.552c0 .431-.22.826-.627 1.042l-2.25 1.294c-.37.216-.85.216-1.255 0l-2.251-1.258c-.37-.216-.628-.611-.628-1.042v-1.654l-1.955 1.115v1.653c0 .431.221.827.627 1.042l4.244 2.372c.369.216.848.216 1.254 0l4.244-2.372c.369-.215.627-.61.627-1.042v-4.78a1.16 1.16 0 00-.627-1.042l-4.28-2.409z" fill="#FFF"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/op.svg' <<'MBUNI_LOGO_EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" class="web3icons">
    <g clip-path="url(#OP__a)">
        <path fill="#FE0420" d="M24 0H0v24h24z"/>
        <path fill="#fff" fill-rule="evenodd" d="M4.859 15.378Q5.729 16 7.09 16q1.65 0 2.633-.744.985-.756 1.386-2.278.24-.933.412-1.922.057-.356.057-.59 0-.777-.4-1.333a2.4 2.4 0 0 0-1.1-.844Q9.381 7.999 8.5 8q-3.24 0-4.018 3.056a36 36 0 0 0-.424 1.922 4 4 0 0 0-.057.6q0 1.166.859 1.8m4.133-2.467c-.22.85-.824 1.405-1.74 1.405-.907 0-1.217-.613-1.054-1.405q.206-1.077.412-1.822c.237-.919.793-1.405 1.74-1.405.903 0 1.2.605 1.042 1.405a26 26 0 0 1-.4 1.822m3.469 3.009q.066.08.19.08h1.514a.33.33 0 0 0 .211-.08.33.33 0 0 0 .123-.206l.478-2.24h1.541c.973 0 1.734-.472 2.29-.891q.848-.63 1.125-1.943.067-.309.067-.594 0-.995-.757-1.52Q18.496 8 17.26 8h-2.963a.34.34 0 0 0-.211.08.33.33 0 0 0-.123.206l-1.537 7.428a.28.28 0 0 0 .034.206m5.412-5.303c-.139.612-.672 1.172-1.299 1.172h-1.28l.44-2.105h1.337c.455 0 .835.09.835.59q0 .15-.033.343" clip-rule="evenodd"/>
    </g>
    <defs>
        <clipPath id="OP__a">
            <path fill="#fff" d="M0 0h24v24H0z"/>
        </clipPath>
    </defs>
</svg>
MBUNI_LOGO_EOF
w 'public/crypto/sol.svg' <<'MBUNI_LOGO_EOF'
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg"><g fill="none"><circle fill="#66F9A1" cx="16" cy="16" r="16"/><path d="M9.925 19.687a.59.59 0 01.415-.17h14.366a.29.29 0 01.207.497l-2.838 2.815a.59.59 0 01-.415.171H7.294a.291.291 0 01-.207-.498l2.838-2.815zm0-10.517A.59.59 0 0110.34 9h14.366c.261 0 .392.314.207.498l-2.838 2.815a.59.59 0 01-.415.17H7.294a.291.291 0 01-.207-.497L9.925 9.17zm12.15 5.225a.59.59 0 00-.415-.17H7.294a.291.291 0 00-.207.498l2.838 2.815c.11.109.26.17.415.17h14.366a.291.291 0 00.207-.498l-2.838-2.815z" fill="#FFF"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/ton.svg' <<'MBUNI_LOGO_EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" fill="none" viewBox="0 0 24 24" class="web3icons">
    <g clip-path="url(#ton__a)">
        <path fill="#0098EA" d="M24 0H0v24h24z"/>
        <path fill="#fff" d="M17.402 4H6.597C4.61 4 3.351 6.143 4.35 7.875l6.67 11.559a1.132 1.132 0 0 0 1.96 0l6.67-11.559C20.648 6.145 19.39 4 17.404 4zm-6.388 11.968L9.56 13.157 6.057 6.89a.612.612 0 0 1 .539-.916h4.416v9.995zm6.926-9.08-3.503 6.27-1.453 2.81V5.973h4.417c.484 0 .77.514.538.915"/>
    </g>
    <defs>
        <clipPath id="ton__a">
            <path fill="#fff" d="M0 0h24v24H0z"/>
        </clipPath>
    </defs>
</svg>
MBUNI_LOGO_EOF
w 'public/crypto/usdt.svg' <<'MBUNI_LOGO_EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><g fill="none" fill-rule="evenodd"><circle cx="16" cy="16" r="16" fill="#26A17B"/><path fill="#FFF" d="M17.922 17.383v-.002c-.11.008-.677.042-1.942.042-1.01 0-1.721-.03-1.971-.042v.003c-3.888-.171-6.79-.848-6.79-1.658 0-.809 2.902-1.486 6.79-1.66v2.644c.254.018.982.061 1.988.061 1.207 0 1.812-.05 1.925-.06v-2.643c3.88.173 6.775.85 6.775 1.658 0 .81-2.895 1.485-6.775 1.657m0-3.59v-2.366h5.414V7.819H8.595v3.608h5.414v2.365c-4.4.202-7.709 1.074-7.709 2.118 0 1.044 3.309 1.915 7.709 2.118v7.582h3.913v-7.584c4.393-.202 7.694-1.073 7.694-2.116 0-1.043-3.301-1.914-7.694-2.117"/></g></svg>
MBUNI_LOGO_EOF
w 'public/crypto/xrp.svg' <<'MBUNI_LOGO_EOF'
<svg width="32" height="32" viewBox="0 0 32 32" xmlns="http://www.w3.org/2000/svg"><g fill="none"><circle cx="16" cy="16" r="16" fill="#23292F"/><path d="M23.07 8h2.89l-6.015 5.957a5.621 5.621 0 01-7.89 0L6.035 8H8.93l4.57 4.523a3.556 3.556 0 004.996 0L23.07 8zM8.895 24.563H6l6.055-5.993a5.621 5.621 0 017.89 0L26 24.562h-2.895L18.5 20a3.556 3.556 0 00-4.996 0l-4.61 4.563z" fill="#FFF"/></g></svg>
MBUNI_LOGO_EOF
w 'src/components/opencex/auth/onboarding-screen.tsx' <<'MBUNI_LOGO_EOF'
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  ArrowRight,
  ArrowLeft,
  Check,
  Star,
  ShieldCheck,
  Fingerprint,
  Loader2,
  Sparkles,
  GraduationCap,
  Briefcase,
  Landmark,
} from "lucide-react";
import { useOpenCEX } from "@/lib/opencex/store";
import { ASSET_METADATA } from "@/lib/opencex/seed";
import { OstrichLogo } from "@/components/opencex/ostrich-logo";
import { toast } from "sonner";
import { CoinIcon } from "@/components/opencex/coin-icon";

type Experience = "NOVICE" | "INTERMEDIATE" | "PRO" | "INSTITUTIONAL";

interface Prefs {
  experience: Experience;
  followedPairs: string[];
  enable2FA: boolean;
  passkeyEnrolled: boolean;
  acceptedTerms: boolean;
}

const STEPS = ["Experience", "Markets", "Security", "Review"] as const;

const EXPERIENCES: { key: Experience; label: string; description: string; icon: React.ComponentType<{ className?: string }>; tier: number }[] = [
  { key: "NOVICE", label: "Beginner", description: "New to crypto — guide me through everything", icon: GraduationCap, tier: 0 },
  { key: "INTERMEDIATE", label: "Intermediate", description: "I know the basics — show me the pro tools", icon: Briefcase, tier: 1 },
  { key: "PRO", label: "Professional", description: "Active trader — give me everything", icon: Sparkles, tier: 3 },
  { key: "INSTITUTIONAL", label: "Institutional", description: "High-volume desk — APIs, custody, reports", icon: Landmark, tier: 5 },
];

export function OnboardingScreen({ onComplete }: { onComplete: () => void }) {
  const pairs = useOpenCEX((s) => s.pairs);
  const [step, setStep] = useState(0);
  const [prefs, setPrefs] = useState<Prefs>({
    experience: "INTERMEDIATE",
    followedPairs: ["BTC/USDT", "ETH/USDT", "SOL/USDT"],
    enable2FA: false,
    passkeyEnrolled: false,
    acceptedTerms: false,
  });
  const [saving, setSaving] = useState(false);

  const togglePair = (sym: string) => {
    setPrefs((p) => ({
      ...p,
      followedPairs: p.followedPairs.includes(sym)
        ? p.followedPairs.filter((x) => x !== sym)
        : [...p.followedPairs, sym],
    }));
  };

  const submit = async () => {
    if (saving) return;
    if (!prefs.acceptedTerms) {
      toast.error("Please accept the terms to continue");
      return;
    }
    setSaving(true);
    try {
      const res = await fetch("/api/onboarding", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(prefs),
      });
      const data = await res.json();
      if (!data.ok) {
        toast.error(data.error ?? "Failed to save preferences");
        setSaving(false);
        return;
      }
      toast.success("Onboarding complete · welcome to Mbuni CEX");
      setTimeout(onComplete, 300);
    } catch (e) {
      toast.error((e as Error).message);
      setSaving(false);
    }
  };

  const next = () => {
    if (step === 0 && !prefs.experience) {
      toast.error("Pick an experience level");
      return;
    }
    if (step === 1 && prefs.followedPairs.length === 0) {
      toast.error("Follow at least one market");
      return;
    }
    if (step < STEPS.length - 1) setStep(step + 1);
    else submit();
  };

  const prev = () => setStep((s) => Math.max(0, s - 1));

  return (
    <div className="min-h-screen flex flex-col bg-background relative overflow-hidden">
      <div
        className="absolute inset-0 opacity-[0.06]"
        style={{
          backgroundImage:
            "linear-gradient(to right, oklch(0.4 0.008 250) 1px, transparent 1px), linear-gradient(to bottom, oklch(0.4 0.008 250) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      />

      {/* Header + progress */}
      <div className="relative px-6 pt-6 max-w-3xl mx-auto w-full">
        <div className="flex items-center gap-2 mb-4">
          <div className="w-8 h-8 rounded-md bg-gradient-to-br from-emerald-400 to-cyan-500 flex items-center justify-center text-black overflow-hidden">
            <OstrichLogo className="w-7 h-7" />
          </div>
          <span className="font-bold text-sm">Mbuni CEX · Onboarding</span>
        </div>
        <div className="flex gap-2">
          {STEPS.map((s, i) => (
            <div key={s} className="flex-1">
              <div
                className={`h-1 rounded-full transition-colors ${
                  i <= step ? "bg-primary" : "bg-elevated-foreground/30"
                }`}
              />
              <div className={`text-[10px] mt-1.5 ${i === step ? "text-foreground font-medium" : "text-secondary"}`}>
                {s}
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Content */}
      <div className="relative flex-1 flex items-center justify-center p-6 max-w-3xl mx-auto w-full">
        <AnimatePresence mode="wait">
          <motion.div
            key={step}
            initial={{ opacity: 0, x: 30 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -30 }}
            transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
            className="w-full"
          >
            {step === 0 && (
              <StepExperience
                value={prefs.experience}
                onChange={(experience) => setPrefs({ ...prefs, experience })}
              />
            )}
            {step === 1 && (
              <StepMarkets
                pairs={pairs.map((p) => p.symbol)}
                selected={prefs.followedPairs}
                onToggle={togglePair}
              />
            )}
            {step === 2 && (
              <StepSecurity
                enable2FA={prefs.enable2FA}
                passkeyEnrolled={prefs.passkeyEnrolled}
                onChange={(p) => setPrefs({ ...prefs, ...p })}
              />
            )}
            {step === 3 && <StepReview prefs={prefs} onToggleTerms={() => setPrefs({ ...prefs, acceptedTerms: !prefs.acceptedTerms })} />}
          </motion.div>
        </AnimatePresence>
      </div>

      {/* Footer nav */}
      <div className="relative px-6 pb-6 max-w-3xl mx-auto w-full">
        <div className="flex items-center justify-between">
          <button
            onClick={prev}
            disabled={step === 0}
            className="flex items-center gap-1 px-3 py-2 rounded-md text-sm text-secondary hover:text-foreground disabled:opacity-40"
          >
            <ArrowLeft className="w-4 h-4" /> Back
          </button>
          <button
            onClick={next}
            disabled={saving}
            className="flex items-center gap-2 px-4 py-2 rounded-md bg-primary hover:bg-primary disabled:opacity-50 text-black text-sm font-semibold transition-colors"
          >
            {saving && <Loader2 className="w-4 h-4 animate-spin" />}
            {saving
              ? "Saving…"
              : step === STEPS.length - 1
              ? "Enter Mbuni CEX"
              : "Continue"}
            {!saving && <ArrowRight className="w-4 h-4" />}
          </button>
        </div>
      </div>
    </div>
  );
}

/* ---------- Step 1: Experience ---------- */
function StepExperience({ value, onChange }: { value: Experience; onChange: (e: Experience) => void }) {
  return (
    <div>
      <h2 className="text-2xl font-bold tracking-tight">How would you describe yourself?</h2>
      <p className="text-sm text-secondary mt-1 mb-6">We&apos;ll tune the experience and your default fee tier accordingly.</p>

      <div className="grid sm:grid-cols-2 gap-2">
        {EXPERIENCES.map((e) => {
          const Icon = e.icon;
          const active = value === e.key;
          return (
            <button
              key={e.key}
              onClick={() => onChange(e.key)}
              className={`text-left p-4 rounded-lg border transition-all flex items-start gap-3 ${
                active ? "border-primary bg-primary/10" : "border-border hover:border-border/80 hover:bg-elevated/50"
              }`}
            >
              <div className={`w-9 h-9 rounded-md flex items-center justify-center shrink-0 ${active ? "bg-primary text-black" : "bg-elevated/60 text-secondary"}`}>
                <Icon className="w-4 h-4" />
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between">
                  <span className="font-semibold text-sm">{e.label}</span>
                  <span className="text-[10px] px-1.5 py-0.5 rounded bg-elevated/60 text-secondary">T{e.tier}</span>
                </div>
                <p className="text-xs text-secondary mt-0.5">{e.description}</p>
              </div>
              {active && <Check className="w-4 h-4 text-primary shrink-0" />}
            </button>
          );
        })}
      </div>
    </div>
  );
}

/* ---------- Step 2: Markets ---------- */
function StepMarkets({
  pairs,
  selected,
  onToggle,
}: {
  pairs: string[];
  selected: string[];
  onToggle: (sym: string) => void;
}) {
  return (
    <div>
      <h2 className="text-2xl font-bold tracking-tight">Follow your markets</h2>
      <p className="text-sm text-secondary mt-1 mb-6">
        We&apos;ll pin these to your sidebar and dashboard. Selected: <span className="text-primary font-medium">{selected.length}</span>
      </p>

      <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
        {pairs.map((sym) => {
          const base = sym.split("/")[0];
          const meta = ASSET_METADATA[base];
          const active = selected.includes(sym);
          return (
            <button
              key={sym}
              onClick={() => onToggle(sym)}
              className={`p-3 rounded-lg border flex items-center gap-2 transition-all ${
                active ? "border-primary bg-primary/10" : "border-border hover:bg-elevated/50"
              }`}
            >
              <CoinIcon asset={base} size={28} />
              <div className="flex-1 min-w-0">
                <div className="text-xs font-medium">{sym}</div>
                <div className="text-[10px] text-secondary truncate">{meta?.name}</div>
              </div>
              {active ? (
                <Star className="w-3.5 h-3.5 fill-gold text-gold shrink-0" />
              ) : (
                <Star className="w-3.5 h-3.5 text-secondary/40 shrink-0" />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}

/* ---------- Step 3: Security ---------- */
function StepSecurity({
  enable2FA,
  passkeyEnrolled,
  onChange,
}: {
  enable2FA: boolean;
  passkeyEnrolled: boolean;
  onChange: (p: { enable2FA?: boolean; passkeyEnrolled?: boolean }) => void;
}) {
  return (
    <div>
      <h2 className="text-2xl font-bold tracking-tight">Secure your account</h2>
      <p className="text-sm text-secondary mt-1 mb-6">
        Recommended for any account holding crypto. You can change these later in Settings.
      </p>

      <div className="space-y-3">
        <SecurityCard
          icon={ShieldCheck}
          title="Two-factor authentication"
          description="Require a TOTP code from your authenticator app on every login and withdrawal."
          accent="from-emerald-400 to-cyan-500"
          enabled={enable2FA}
          onToggle={() => onChange({ enable2FA: !enable2FA })}
        />
        <SecurityCard
          icon={Fingerprint}
          title="Passkey / WebAuthn"
          description="Sign in with device biometrics (Face ID, Touch ID, security key). No password needed."
          accent="from-purple-400 to-pink-500"
          enabled={passkeyEnrolled}
          onToggle={() => onChange({ passkeyEnrolled: !passkeyEnrolled })}
        />
        <div className="bg-elevated/40 border border-border rounded-lg p-3 flex items-start gap-3 text-xs">
          <ShieldCheck className="w-4 h-4 text-primary mt-0.5 shrink-0" />
          <div className="text-secondary">
            <span className="text-foreground font-medium">Always enforced:</span> Withdrawal address whitelisting with 24h time-lock, hot wallet caps, and complete audit trail. These cannot be disabled.
          </div>
        </div>
      </div>
    </div>
  );
}

function SecurityCard({
  icon: Icon,
  title,
  description,
  accent,
  enabled,
  onToggle,
}: {
  icon: React.ComponentType<{ className?: string }>;
  title: string;
  description: string;
  accent: string;
  enabled: boolean;
  onToggle: () => void;
}) {
  return (
    <div className={`p-4 rounded-lg border flex items-start gap-3 transition-all ${enabled ? "border-primary bg-primary/5" : "border-border"}`}>
      <div className={`w-9 h-9 rounded-md bg-gradient-to-br ${accent} flex items-center justify-center shrink-0`}>
        <Icon className="w-4 h-4 text-black" />
      </div>
      <div className="flex-1">
        <div className="font-semibold text-sm">{title}</div>
        <p className="text-xs text-secondary mt-0.5">{description}</p>
      </div>
      <button
        onClick={onToggle}
        className={`relative w-10 h-6 rounded-full transition-colors shrink-0 ${enabled ? "bg-primary" : "bg-elevated-foreground/30"}`}
      >
        <motion.span
          className="absolute top-0.5 left-0.5 w-5 h-5 rounded-full bg-white shadow"
          animate={{ x: enabled ? 16 : 0 }}
          transition={{ type: "spring", stiffness: 400, damping: 30 }}
        />
      </button>
    </div>
  );
}

/* ---------- Step 4: Review ---------- */
function StepReview({ prefs, onToggleTerms }: { prefs: Prefs; onToggleTerms: () => void }) {
  const experience = EXPERIENCES.find((e) => e.key === prefs.experience)!;
  return (
    <div>
      <h2 className="text-2xl font-bold tracking-tight">Review &amp; accept</h2>
      <p className="text-sm text-secondary mt-1 mb-6">Confirm your setup before entering the exchange.</p>

      <div className="space-y-2 mb-5">
        <Row label="Experience" value={experience.label} badge={`Tier ${experience.tier}`} />
        <Row label="Followed markets" value={`${prefs.followedPairs.length} pair${prefs.followedPairs.length === 1 ? "" : "s"}`} detail={prefs.followedPairs.join(", ")} />
        <Row label="Two-factor auth" value={prefs.enable2FA ? "Enabled" : "Off"} tone={prefs.enable2FA ? "up" : "muted"} />
        <Row label="Passkey / WebAuthn" value={prefs.passkeyEnrolled ? "Enrolled" : "Not enrolled"} tone={prefs.passkeyEnrolled ? "up" : "muted"} />
      </div>

      <label className="flex items-start gap-3 p-3 bg-elevated/40 border border-border rounded-lg cursor-pointer hover:bg-elevated/50">
        <input
          type="checkbox"
          checked={prefs.acceptedTerms}
          onChange={onToggleTerms}
          className="mt-0.5 w-4 h-4 accent-emerald-500"
        />
        <span className="text-xs text-secondary">
          I agree to the <a className="text-primary hover:underline">Terms of Service</a>, acknowledge the{" "}
          <a className="text-primary hover:underline">Risk Disclosure</a>, and confirm I am 18+ and not a
          resident of a restricted jurisdiction.
        </span>
      </label>
    </div>
  );
}

function Row({ label, value, detail, badge, tone }: { label: string; value: string; detail?: string; badge?: string; tone?: "up" | "muted" }) {
  const color = tone === "up" ? "text-primary" : tone === "muted" ? "text-secondary" : "text-foreground";
  return (
    <div className="flex items-center justify-between py-2 border-b border-border/40">
      <span className="text-xs text-secondary">{label}</span>
      <div className="text-right">
        <div className={`text-sm font-medium ${color}`}>
          {value} {badge && <span className="ml-1 text-[10px] px-1.5 py-0.5 rounded bg-elevated/60 text-secondary">{badge}</span>}
        </div>
        {detail && <div className="text-[10px] text-secondary mt-0.5 truncate max-w-[200px]">{detail}</div>}
      </div>
    </div>
  );
}
MBUNI_LOGO_EOF
w 'src/components/opencex/auth/welcome-screen.tsx' <<'MBUNI_LOGO_EOF'
"use client";

import { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { ArrowRight, Cpu, ShieldCheck, CandlestickChart, ChevronLeft, ChevronRight } from "lucide-react";
import { ASSET_METADATA } from "@/lib/opencex/seed";
import { CoinIcon } from "@/components/opencex/coin-icon";

const COINS = ["BTC", "ETH", "SOL", "USDT", "BNB", "XRP", "ARB", "OP"];

interface Slide {
  eyebrow: string;
  title: string;
  description: string;
  icon: React.ComponentType<{ className?: string }>;
  accent: string;
  visual: React.ReactNode;
}

const SLIDES: Slide[] = [
  {
    eyebrow: "Matching Engine",
    title: "Rust-grade performance,\nin your browser.",
    description:
      "A faithful TypeScript reimplementation of the production Rust matching engine — price-time priority, all 5 order types (LIMIT, MARKET, IOC, FOK, POST_ONLY), sub-millisecond order processing.",
    icon: Cpu,
    accent: "from-orange-400 to-red-500",
    visual: <EngineVisual />,
  },
  {
    eyebrow: "Hybrid Custody",
    title: "Multi-chain wallet,\nyou stay in control.",
    description:
      "Deposits and withdrawals across 10 chains — Bitcoin, Ethereum, Solana, TON, Tron and more. HSM-backed hot wallet, optional MPC, address whitelisting with 24h time-locks, and hybrid mode where the user signs.",
    icon: ShieldCheck,
    accent: "from-emerald-400 to-cyan-500",
    visual: <CoinsVisual />,
  },
  {
    eyebrow: "Pro CLOB Terminal",
    title: "Trade like a pro,\nanywhere you are.",
    description:
      "Live order book, real-time trade tape, candlestick chart with multiple timeframes, deep order types — plus a mobile-optimized experience with bottom-sheet order entry and tabbed views.",
    icon: CandlestickChart,
    accent: "from-purple-400 to-pink-500",
    visual: <TerminalVisual />,
  },
];

export function WelcomeScreen({ onComplete }: { onComplete: () => void }) {
  const [index, setIndex] = useState(0);
  const slide = SLIDES[index];
  const isLast = index === SLIDES.length - 1;

  const next = () => (isLast ? onComplete() : setIndex((i) => i + 1));
  const prev = () => setIndex((i) => Math.max(0, i - 1));

  return (
    <div className="min-h-screen flex flex-col bg-background relative overflow-hidden">
      {/* Background mesh */}
      <div
        className="absolute inset-0 opacity-[0.06]"
        style={{
          backgroundImage:
            "linear-gradient(to right, oklch(0.4 0.008 250) 1px, transparent 1px), linear-gradient(to bottom, oklch(0.4 0.008 250) 1px, transparent 1px)",
          backgroundSize: "48px 48px",
        }}
      />

      {/* Skip button */}
      <button
        onClick={onComplete}
        className="absolute top-4 right-4 md:top-6 md:right-6 z-10 text-xs text-secondary hover:text-foreground px-3 py-1.5 rounded-md hover:bg-elevated/70 transition-colors"
      >
        Skip
      </button>

      <div className="flex-1 flex flex-col items-center justify-center px-6 relative">
        <div className="w-full max-w-5xl">
          {/* Slide content */}
          <AnimatePresence mode="wait">
            <motion.div
              key={index}
              initial={{ opacity: 0, x: 40 }}
              animate={{ opacity: 1, x: 0 }}
              exit={{ opacity: 0, x: -40 }}
              transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
              className="grid md:grid-cols-2 gap-8 md:gap-12 items-center"
            >
              {/* Left: text */}
              <div className="order-2 md:order-1 text-center md:text-left">
                <div className="flex items-center gap-2 mb-4 justify-center md:justify-start">
                  <div className={`w-8 h-8 rounded-md bg-gradient-to-br ${slide.accent} flex items-center justify-center`}>
                    <slide.icon className="w-4 h-4 text-black" />
                  </div>
                  <span className="text-[11px] uppercase tracking-wider text-secondary font-medium">
                    {slide.eyebrow}
                  </span>
                </div>
                <h2 className="text-2xl md:text-4xl font-bold tracking-tight leading-tight whitespace-pre-line">
                  {slide.title}
                </h2>
                <p className="mt-4 text-sm md:text-base text-secondary leading-relaxed max-w-md mx-auto md:mx-0">
                  {slide.description}
                </p>
              </div>

              {/* Right: visual */}
              <div className="order-1 md:order-2 relative h-64 md:h-80 flex items-center justify-center">
                {slide.visual}
              </div>
            </motion.div>
          </AnimatePresence>
        </div>
      </div>

      {/* Bottom: progress dots + nav */}
      <div className="relative px-6 pb-8 md:pb-10">
        <div className="max-w-5xl mx-auto flex items-center justify-between">
          <div className="flex gap-2">
            {SLIDES.map((_, i) => (
              <button
                key={i}
                onClick={() => setIndex(i)}
                className={`h-1.5 rounded-full transition-all ${
                  i === index ? "w-8 bg-primary" : "w-1.5 bg-elevated-foreground/40 hover:bg-elevated-foreground/70"
                }`}
              />
            ))}
          </div>

          <div className="flex items-center gap-2">
            {index > 0 && (
              <button
                onClick={prev}
                className="p-2 rounded-md text-secondary hover:text-foreground hover:bg-elevated/70"
              >
                <ChevronLeft className="w-5 h-5" />
              </button>
            )}
            <button
              onClick={next}
              className="flex items-center gap-2 px-4 py-2 rounded-md bg-primary hover:bg-primary text-black text-sm font-semibold transition-colors"
            >
              {isLast ? "Get started" : "Continue"}
              <ArrowRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

/* ---------- Visuals ---------- */

function EngineVisual() {
  // Animated order book with random flashing trades
  return (
    <div className="w-full max-w-xs bg-card border border-border rounded-lg p-3 shadow-2xl">
      <div className="flex justify-between text-[10px] text-secondary mb-2">
        <span>BTC/USDT</span>
        <span className="text-primary">LIVE</span>
      </div>
      <div className="space-y-0.5">
        {[
          { p: 67310.2, q: 0.45, side: "ask" },
          { p: 67300.1, q: 0.32, side: "ask" },
          { p: 67290.0, q: 1.18, side: "ask" },
        ].map((l, i) => (
          <motion.div
            key={`a${i}`}
            className="relative grid grid-cols-2 text-xs px-2 py-0.5"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: i * 0.1 }}
          >
            <div className="absolute inset-y-0 right-0 bg-danger/10" style={{ width: `${l.q * 60}%` }} />
            <span className="relative text-danger tabular">{l.p.toFixed(1)}</span>
            <span className="relative text-right tabular text-secondary">{l.q.toFixed(2)}</span>
          </motion.div>
        ))}
        <div className="my-1 py-1 border-y border-border text-center text-sm font-bold tabular text-primary">
          67,285.50
        </div>
        {[
          { p: 67280.5, q: 0.78, side: "bid" },
          { p: 67270.3, q: 0.55, side: "bid" },
          { p: 67260.0, q: 1.42, side: "bid" },
        ].map((l, i) => (
          <motion.div
            key={`b${i}`}
            className="relative grid grid-cols-2 text-xs px-2 py-0.5"
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            transition={{ delay: 0.4 + i * 0.1 }}
          >
            <div className="absolute inset-y-0 right-0 bg-primary/10" style={{ width: `${l.q * 60}%` }} />
            <span className="relative text-primary tabular">{l.p.toFixed(1)}</span>
            <span className="relative text-right tabular text-secondary">{l.q.toFixed(2)}</span>
          </motion.div>
        ))}
      </div>
      <motion.div
        className="mt-2 flex justify-center"
        animate={{ scale: [1, 1.05, 1], opacity: [0.7, 1, 0.7] }}
        transition={{ duration: 1.5, repeat: Infinity }}
      >
        <span className="text-[9px] text-secondary">⚡ p99 latency &lt; 500µs</span>
      </motion.div>
    </div>
  );
}

function CoinsVisual() {
  // Floating coin grid with subtle motion
  return (
    <div className="relative w-full max-w-sm">
      <div className="grid grid-cols-4 gap-3">
        {COINS.map((c, i) => {
          const meta = ASSET_METADATA[c];
          return (
            <motion.div
              key={c}
              className="aspect-square rounded-xl border border-border bg-card flex flex-col items-center justify-center gap-1"
              initial={{ opacity: 0, y: 20, scale: 0.8 }}
              animate={{ opacity: 1, y: 0, scale: 1 }}
              transition={{ delay: i * 0.07, type: "spring", stiffness: 200 }}
              whileHover={{ scale: 1.08, y: -4 }}
            >
              <motion.div
                className="w-9 h-9 rounded-full"
                animate={{ y: [0, -3, 0] }}
                transition={{ duration: 2 + i * 0.2, repeat: Infinity, ease: "easeInOut" }}
              >
                <CoinIcon asset={c} size={36} />
              </motion.div>
              <span className="text-[10px] font-medium">{c}</span>
            </motion.div>
          );
        })}
      </div>
      {/* Chain labels */}
      <motion.div
        className="mt-4 flex flex-wrap gap-1.5 justify-center"
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 0.8 }}
      >
        {["Bitcoin", "Ethereum", "Solana", "TON", "Tron", "Arbitrum"].map((c) => (
          <span key={c} className="text-[10px] px-2 py-0.5 rounded-full bg-elevated/60 text-secondary border border-border/40">
            {c}
          </span>
        ))}
      </motion.div>
    </div>
  );
}

function TerminalVisual() {
  // Stylized candlestick chart with animated last price line
  const candles = [
    { o: 100, c: 104, h: 105, l: 99 },
    { o: 104, c: 102, h: 106, l: 101 },
    { o: 102, c: 108, h: 109, l: 101 },
    { o: 108, c: 106, h: 110, l: 105 },
    { o: 106, c: 112, h: 113, l: 105 },
    { o: 112, c: 110, h: 114, l: 109 },
    { o: 110, c: 116, h: 117, l: 109 },
    { o: 116, c: 114, h: 118, l: 113 },
  ];
  const max = Math.max(...candles.map((c) => c.h));
  const min = Math.min(...candles.map((c) => c.l));
  const range = max - min || 1;

  return (
    <div className="w-full max-w-sm bg-card border border-border rounded-lg p-3 shadow-2xl">
      <div className="flex justify-between text-[10px] text-secondary mb-2">
        <span>BTC/USDT · 1m</span>
        <span className="text-primary">+3.09%</span>
      </div>
      <div className="relative h-32 flex items-end gap-1 px-1">
        {candles.map((c, i) => {
          const up = c.c >= c.o;
          const color = up ? "oklch(0.72 0.18 152)" : "oklch(0.66 0.22 22)";
          const top = ((max - c.h) / range) * 100;
          const height = ((c.h - c.l) / range) * 100;
          const bodyTop = ((max - Math.max(c.o, c.c)) / range) * 100;
          const bodyHeight = (Math.abs(c.c - c.o) / range) * 100;
          return (
            <motion.div
              key={i}
              className="relative flex-1"
              style={{ height: `${100 - top}%`, marginTop: `${top}%` }}
              initial={{ opacity: 0, scaleY: 0 }}
              animate={{ opacity: 1, scaleY: 1 }}
              transition={{ delay: i * 0.08, duration: 0.3 }}
            >
              <div className="absolute inset-0 flex flex-col justify-end">
                <div
                  className="w-1 mx-auto"
                  style={{ height: `${height}%`, background: color, marginTop: `${((c.h - Math.max(c.o, c.c)) / range) * 100 * -1}%` }}
                />
                <div
                  className="w-full"
                  style={{
                    height: `${bodyHeight}%`,
                    background: color,
                    marginTop: 0,
                    opacity: 0.9,
                  }}
                />
              </div>
            </motion.div>
          );
        })}
        {/* Animated price line */}
        <motion.div
          className="absolute left-0 right-0 h-px bg-primary"
          style={{ bottom: "30%" }}
          animate={{ opacity: [0.4, 1, 0.4] }}
          transition={{ duration: 2, repeat: Infinity }}
        />
      </div>
      <div className="mt-2 grid grid-cols-2 gap-1 text-[9px]">
        <div className="px-2 py-1 rounded bg-primary/15 text-primary text-center">BUY 0.05 BTC</div>
        <div className="px-2 py-1 rounded bg-danger/15 text-danger text-center">SELL 0.05 BTC</div>
      </div>
    </div>
  );
}
MBUNI_LOGO_EOF
w 'src/components/opencex/coin-icon.tsx' <<'MBUNI_LOGO_EOF'
"use client";

import { useState } from "react";
import { ASSET_METADATA } from "@/lib/opencex/seed";

// Real logos live in /public/crypto/<symbol>.svg (see LICENSES.md there).
const LOGOS = new Set([
  "BTC", "ETH", "USDT", "SOL", "BNB", "XRP", "DOGE", "MATIC", "AVAX", "LINK", "ADA", "ARB", "OP", "TON",
]);

interface CoinIconProps {
  asset: string;
  /** Pixel size (square). */
  size?: number;
  className?: string;
}

/**
 * Round coin logo. Falls back to the coloured letter badge for assets without
 * a bundled logo, or if the image fails to load.
 */
export function CoinIcon({ asset, size = 24, className = "" }: CoinIconProps) {
  const [failed, setFailed] = useState(false);
  const sym = asset.toUpperCase();

  if (LOGOS.has(sym) && !failed) {
    return (
      <img
        src={`/crypto/${sym.toLowerCase()}.svg`}
        alt={`${sym} logo`}
        width={size}
        height={size}
        loading="lazy"
        decoding="async"
        draggable={false}
        onError={() => setFailed(true)}
        className={`rounded-full shrink-0 bg-white/5 ${className}`}
        style={{ width: size, height: size }}
      />
    );
  }

  return (
    <span
      aria-label={`${sym} logo`}
      className={`rounded-full shrink-0 inline-flex items-center justify-center font-bold text-white ${className}`}
      style={{
        width: size,
        height: size,
        fontSize: Math.max(8, Math.round(size * 0.38)),
        background: ASSET_METADATA[sym]?.color ?? "#666",
      }}
    >
      {sym.slice(0, 2)}
    </span>
  );
}
MBUNI_LOGO_EOF
w 'src/components/opencex/pair-selector.tsx' <<'MBUNI_LOGO_EOF'
"use client";

import { useOpenCEX } from "@/lib/opencex/store";
import { fmtPrice, fmtPct, fmtCompact } from "@/lib/opencex/format";
import { useState } from "react";
import { ChevronDown, Search, Star } from "lucide-react";
import { ASSET_METADATA } from "@/lib/opencex/seed";
import { CoinIcon } from "@/components/opencex/coin-icon";

export function PairSelector() {
  const pairs = useOpenCEX((s) => s.pairs);
  const activePair = useOpenCEX((s) => s.activePair);
  const setActivePair = useOpenCEX((s) => s.setActivePair);
  const tickers = useOpenCEX((s) => s.tickers);
  const [open, setOpen] = useState(false);
  const [q, setQ] = useState("");
  const [favorites, setFavorites] = useState<Set<string>>(new Set(["BTC/USDT", "ETH/USDT", "SOL/USDT"]));

  const active = pairs.find((p) => p.symbol === activePair);
  const ticker = tickers[activePair];
  const filtered = pairs.filter((p) => p.symbol.toLowerCase().includes(q.toLowerCase()));

  const toggleFav = (sym: string, e: React.MouseEvent) => {
    e.stopPropagation();
    setFavorites((s) => {
      const n = new Set(s);
      if (n.has(sym)) n.delete(sym);
      else n.add(sym);
      return n;
    });
  };

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(!open)}
        className="flex items-center gap-2 px-2 md:px-3 py-1.5 rounded hover:bg-elevated/70 min-w-[140px] md:min-w-[180px]"
      >
        {active && (
          <CoinIcon asset={active.base} size={24} />
        )}
        <div className="flex flex-col items-start leading-tight">
          <span className="text-sm font-semibold">{activePair}</span>
          {ticker && (
            <span className={`text-[10px] tabular ${ticker.priceChangePct >= 0 ? "text-primary" : "text-danger"}`}>
              {fmtPrice(ticker.lastPrice, 2)} · {fmtPct(ticker.priceChangePct)}
            </span>
          )}
        </div>
        <ChevronDown className="w-4 h-4 ml-1 text-secondary" />
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute z-50 mt-1 left-0 w-[calc(100vw-1.5rem)] max-w-[420px] bg-popover border border-border rounded-md shadow-xl">
            <div className="p-2 border-b border-border">
              <div className="flex items-center gap-2 px-2 py-1 bg-input rounded">
                <Search className="w-3.5 h-3.5 text-secondary" />
                <input
                  autoFocus
                  value={q}
                  onChange={(e) => setQ(e.target.value)}
                  placeholder="Search markets…"
                  className="flex-1 bg-transparent text-sm outline-none"
                />
              </div>
            </div>
            <div className="grid grid-cols-5 gap-2 px-3 py-1.5 text-[10px] uppercase text-secondary border-b border-border">
              <span className="col-span-2">Pair</span>
              <span className="text-right">Last Price</span>
              <span className="text-right">24h Change</span>
              <span className="text-right">24h Vol</span>
            </div>
            <div className="max-h-80 overflow-y-auto">
              {filtered.map((p) => {
                const t = tickers[p.symbol];
                return (
                  <button
                    key={p.symbol}
                    onClick={() => {
                      setActivePair(p.symbol);
                      setOpen(false);
                    }}
                    className={`w-full grid grid-cols-5 gap-2 px-3 py-1.5 text-xs hover:bg-elevated/60 items-center tabular ${
                      p.symbol === activePair ? "bg-elevated/60" : ""
                    }`}
                  >
                    <span className="col-span-2 flex items-center gap-2">
                      <Star
                        className={`w-3 h-3 ${favorites.has(p.symbol) ? "fill-gold text-gold" : "text-secondary"}`}
                        onClick={(e) => toggleFav(p.symbol, e)}
                      />
                      <CoinIcon asset={p.base} size={16} />
                      <span className="font-medium">{p.symbol}</span>
                    </span>
                    <span className="text-right">{t ? fmtPrice(t.lastPrice, p.priceDecimals) : "—"}</span>
                    <span className={`text-right ${t && t.priceChangePct >= 0 ? "text-primary" : "text-danger"}`}>
                      {t ? fmtPct(t.priceChangePct) : "—"}
                    </span>
                    <span className="text-right text-secondary">{t ? fmtCompact(t.quoteVolume) : "—"}</span>
                  </button>
                );
              })}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
MBUNI_LOGO_EOF
w 'src/components/opencex/views/markets.tsx' <<'MBUNI_LOGO_EOF'
"use client";

import { useOpenCEX } from "@/lib/opencex/store";
import { fmtPrice, fmtPct, fmtCompact } from "@/lib/opencex/format";
import { ASSET_METADATA } from "@/lib/opencex/seed";
import { Star, TrendingUp, TrendingDown } from "lucide-react";
import { useState } from "react";
import { CoinIcon } from "@/components/opencex/coin-icon";

export function MarketsView({ onOpenTrading }: { onOpenTrading: (pair: string) => void }) {
  const pairs = useOpenCEX((s) => s.pairs);
  const tickers = useOpenCEX((s) => s.tickers);
  const [favorites, setFavorites] = useState<Set<string>>(new Set(["BTC/USDT", "ETH/USDT", "SOL/USDT"]));
  const [tab, setTab] = useState<"all" | "fav" | "gainers" | "losers">("all");

  const rows = pairs
    .map((p) => ({ pair: p, ticker: tickers[p.symbol] }))
    .filter((r) => r.ticker);

  const visible = rows.filter((r) => {
    if (tab === "fav") return favorites.has(r.pair.symbol);
    if (tab === "gainers") return r.ticker!.priceChangePct > 0;
    if (tab === "losers") return r.ticker!.priceChangePct < 0;
    return true;
  });

  const totalVol = rows.reduce((s, r) => s + (r.ticker?.quoteVolume ?? 0), 0);
  const gainers = rows.filter((r) => r.ticker!.priceChangePct > 0).length;
  const losers = rows.filter((r) => r.ticker!.priceChangePct < 0).length;

  const toggleFav = (sym: string) => {
    setFavorites((s) => {
      const n = new Set(s);
      if (n.has(sym)) n.delete(sym);
      else n.add(sym);
      return n;
    });
  };

  return (
    <div className="p-3 md:p-4 space-y-4">
      {/* Stats summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2 md:gap-3">
        <SummaryCard label="Markets" value={String(pairs.length)} sub="active pairs" />
        <SummaryCard label="24h Volume" value={`$${fmtCompact(totalVol)}`} sub="all pairs" />
        <SummaryCard label="Gainers" value={String(gainers)} sub="24h" tone="up" />
        <SummaryCard label="Losers" value={String(losers)} sub="24h" tone="down" />
      </div>

      {/* Tabs */}
      <div className="flex items-center gap-1 border-b border-border overflow-x-auto no-scrollbar">
        {(["all", "fav", "gainers", "losers"] as const).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-3 py-2 text-xs font-medium border-b-2 transition-colors shrink-0 ${
              tab === t ? "border-primary text-foreground" : "border-transparent text-secondary hover:text-foreground"
            }`}
          >
            {t === "all" ? "All Markets" : t === "fav" ? "★ Favorites" : t === "gainers" ? "Gainers" : "Losers"}
          </button>
        ))}
      </div>

      {/* Markets — desktop table */}
      <div className="hidden md:block bg-card border border-border rounded-md overflow-hidden">
        <div className="grid grid-cols-12 gap-2 px-4 py-2 text-[10px] uppercase text-secondary border-b border-border">
          <span className="col-span-1"></span>
          <span className="col-span-3">Pair</span>
          <span className="col-span-2 text-right">Last Price</span>
          <span className="col-span-2 text-right">24h Change</span>
          <span className="col-span-2 text-right">24h High</span>
          <span className="col-span-1 text-right">24h Vol</span>
          <span className="col-span-1 text-right">Trade</span>
        </div>
        <div className="max-h-[calc(100vh-22rem)] overflow-y-auto">
          {visible.map(({ pair, ticker }) => {
            const t = ticker!;
            const isFav = favorites.has(pair.symbol);
            const up = t.priceChangePct >= 0;
            return (
              <button
                key={pair.symbol}
                onClick={() => onOpenTrading(pair.symbol)}
                className="w-full grid grid-cols-12 gap-2 px-4 py-2.5 text-xs items-center hover:bg-elevated/50 border-b border-border/40 tabular"
              >
                <span
                  className="col-span-1"
                  onClick={(e) => {
                    e.stopPropagation();
                    toggleFav(pair.symbol);
                  }}
                >
                  <Star className={`w-3.5 h-3.5 ${isFav ? "fill-gold text-gold" : "text-secondary"}`} />
                </span>
                <span className="col-span-3 flex items-center gap-2">
                  <CoinIcon asset={pair.base} size={20} />
                  <span className="flex flex-col items-start leading-tight">
                    <span className="font-medium text-sm text-foreground">{pair.base}<span className="text-secondary">/{pair.quote}</span></span>
                    <span className="text-[10px] text-secondary">{ASSET_METADATA[pair.base]?.name}</span>
                  </span>
                </span>
                <span className="col-span-2 text-right font-medium">{fmtPrice(t.lastPrice, pair.priceDecimals)}</span>
                <span className={`col-span-2 text-right flex items-center justify-end gap-1 ${up ? "text-primary" : "text-danger"}`}>
                  {up ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                  {fmtPct(t.priceChangePct)}
                </span>
                <span className="col-span-2 text-right text-secondary">{fmtPrice(t.high, pair.priceDecimals)}</span>
                <span className="col-span-1 text-right text-secondary">{fmtCompact(t.volume)}</span>
                <span className="col-span-1 text-right">
                  <span className="text-[10px] px-2 py-0.5 rounded bg-primary/10 text-primary">Trade</span>
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Markets — mobile card list */}
      <div className="md:hidden space-y-2">
        {visible.map(({ pair, ticker }) => {
          const t = ticker!;
          const isFav = favorites.has(pair.symbol);
          const up = t.priceChangePct >= 0;
          return (
            <button
              key={pair.symbol}
              onClick={() => onOpenTrading(pair.symbol)}
              className="w-full bg-card border border-border rounded-md p-3 text-left active:bg-elevated/50"
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleFav(pair.symbol);
                    }}
                    className="p-1 -ml-1"
                  >
                    <Star className={`w-3.5 h-3.5 ${isFav ? "fill-gold text-gold" : "text-secondary"}`} />
                  </span>
                  <CoinIcon asset={pair.base} size={28} />
                  <div className="flex flex-col leading-tight">
                    <span className="font-semibold text-sm">{pair.base}<span className="text-secondary font-normal">/{pair.quote}</span></span>
                    <span className="text-[10px] text-secondary">{ASSET_METADATA[pair.base]?.name}</span>
                  </div>
                </div>
                <div className="text-right">
                  <div className="text-sm font-semibold tabular">{fmtPrice(t.lastPrice, pair.priceDecimals)}</div>
                  <div className={`text-xs tabular flex items-center justify-end gap-0.5 ${up ? "text-primary" : "text-danger"}`}>
                    {up ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
                    {fmtPct(t.priceChangePct)}
                  </div>
                </div>
              </div>
              <div className="flex justify-between mt-2 pt-2 border-t border-border/40 text-[10px] text-secondary tabular">
                <span>H: <span className="text-foreground">{fmtPrice(t.high, pair.priceDecimals)}</span></span>
                <span>L: <span className="text-foreground">{fmtPrice(t.low, pair.priceDecimals)}</span></span>
                <span>Vol: <span className="text-foreground">{fmtCompact(t.quoteVolume)} USDT</span></span>
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
}

function SummaryCard({ label, value, sub, tone }: { label: string; value: string; sub: string; tone?: "up" | "down" }) {
  const color = tone === "up" ? "text-primary" : tone === "down" ? "text-danger" : "text-foreground";
  return (
    <div className="bg-card border border-border rounded-md p-3 md:p-4">
      <div className="text-[10px] uppercase text-secondary tracking-wider">{label}</div>
      <div className={`text-lg md:text-2xl font-bold tabular mt-1 ${color}`}>{value}</div>
      <div className="text-[11px] text-secondary mt-0.5">{sub}</div>
    </div>
  );
}
MBUNI_LOGO_EOF
w 'src/components/opencex/views/wallet.tsx' <<'MBUNI_LOGO_EOF'
"use client";

import { useOpenCEX } from "@/lib/opencex/store";
import { fmtQty, fmtUSD, fmtDateTime, shortAddr, shortHash } from "@/lib/opencex/format";
import { ASSET_METADATA, CHAINS } from "@/lib/opencex/seed";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowDownToLine, ArrowUpFromLine, Shield, Plus, Copy, Check } from "lucide-react";
import { useState } from "react";
import { toast } from "sonner";
import type { Deposit, Withdrawal } from "@/lib/opencex/types";
import { CoinIcon } from "@/components/opencex/coin-icon";

export function WalletView() {
  const balances = useOpenCEX((s) => s.balances);
  const deposits = useOpenCEX((s) => s.deposits);
  const withdrawals = useOpenCEX((s) => s.withdrawals);
  const whitelist = useOpenCEX((s) => s.whitelist);
  const pairs = useOpenCEX((s) => s.pairs);

  const totalUSD = balances.reduce((s, b) => s + b.usdValue, 0);
  const totalLocked = balances.reduce((s, b) => s + b.locked * (getUSDPrice(b.asset, pairs) ?? 0), 0);

  return (
    <div className="p-3 md:p-4 space-y-4">
      {/* Portfolio summary */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-2 md:gap-3">
        <Card className="p-3 md:p-4">
          <div className="text-[10px] uppercase text-secondary tracking-wider">Total Balance</div>
          <div className="text-lg md:text-2xl font-bold tabular mt-1">{fmtUSD(totalUSD)}</div>
          <div className="text-[11px] text-primary mt-0.5">+2.4% 24h</div>
        </Card>
        <Card className="p-3 md:p-4">
          <div className="text-[10px] uppercase text-secondary tracking-wider">Locked</div>
          <div className="text-lg md:text-2xl font-bold tabular mt-1">{fmtUSD(totalLocked)}</div>
          <div className="text-[11px] text-secondary mt-0.5">{balances.filter((b) => b.locked > 0).length} assets</div>
        </Card>
        <Card className="p-3 md:p-4">
          <div className="text-[10px] uppercase text-secondary tracking-wider">Available</div>
          <div className="text-lg md:text-2xl font-bold tabular mt-1">{fmtUSD(totalUSD - totalLocked)}</div>
          <div className="text-[11px] text-secondary mt-0.5">For trading & withdrawal</div>
        </Card>
        <Card className="p-3 md:p-4">
          <div className="text-[10px] uppercase text-secondary tracking-wider">Custody Mode</div>
          <div className="text-lg md:text-2xl font-bold mt-1">Hybrid</div>
          <div className="text-[11px] text-secondary mt-0.5">HSM · Passkey · Whitelist</div>
        </Card>
      </div>

      <Tabs defaultValue="balances">
        <TabsList className="flex w-auto overflow-x-auto no-scrollbar">
          <TabsTrigger value="balances">Balances</TabsTrigger>
          <TabsTrigger value="deposits">Deposits</TabsTrigger>
          <TabsTrigger value="withdrawals">Withdrawals</TabsTrigger>
          <TabsTrigger value="whitelist">Whitelist</TabsTrigger>
        </TabsList>

        <TabsContent value="balances" className="mt-3">
          {/* Desktop table */}
          <Card className="overflow-hidden hidden md:block">
            <div className="grid grid-cols-12 gap-2 px-4 py-2 text-[10px] uppercase text-secondary border-b border-border">
              <span className="col-span-3">Asset</span>
              <span className="col-span-3 text-right">Total</span>
              <span className="col-span-2 text-right">Available</span>
              <span className="col-span-2 text-right">Locked</span>
              <span className="col-span-1 text-right">USD Value</span>
              <span className="col-span-1 text-right">Action</span>
            </div>
            <div className="max-h-[60vh] overflow-y-auto">
              {balances.map((b) => {
                const meta = ASSET_METADATA[b.asset];
                return (
                  <div key={b.asset} className="grid grid-cols-12 gap-2 px-4 py-2.5 text-xs items-center border-b border-border/40 tabular hover:bg-elevated/40">
                    <span className="col-span-3 flex items-center gap-2">
                      <CoinIcon asset={b.asset} size={28} />
                      <span className="flex flex-col leading-tight">
                        <span className="font-medium text-sm">{b.asset}</span>
                        <span className="text-[10px] text-secondary">{meta?.name}</span>
                      </span>
                    </span>
                    <span className="col-span-3 text-right font-medium">{fmtQty(b.free + b.locked, 6)} {b.asset}</span>
                    <span className="col-span-2 text-right">{fmtQty(b.free, 6)}</span>
                    <span className="col-span-2 text-right text-gold">{fmtQty(b.locked, 6)}</span>
                    <span className="col-span-1 text-right text-secondary">{fmtUSD(b.usdValue)}</span>
                    <span className="col-span-1 flex justify-end gap-1">
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-7 px-2 text-[11px] text-primary hover:text-primary-hover"
                        onClick={() => toast.info(`Deposit ${b.asset}`, { description: `Generate ${meta?.chains[0] ?? "chain"} address` })}
                      >
                        <ArrowDownToLine className="w-3 h-3" />
                      </Button>
                      <Button
                        size="sm"
                        variant="ghost"
                        className="h-7 px-2 text-[11px] text-danger hover:text-danger"
                        onClick={() => toast.info(`Withdraw ${b.asset}`)}
                      >
                        <ArrowUpFromLine className="w-3 h-3" />
                      </Button>
                    </span>
                  </div>
                );
              })}
            </div>
          </Card>

          {/* Mobile card list */}
          <div className="md:hidden space-y-2">
            {balances.map((b) => {
              const meta = ASSET_METADATA[b.asset];
              return (
                <Card key={b.asset} className="p-3">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <CoinIcon asset={b.asset} size={32} />
                      <div className="flex flex-col leading-tight">
                        <span className="font-medium text-sm">{b.asset}</span>
                        <span className="text-[10px] text-secondary">{meta?.name}</span>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="text-sm font-semibold tabular">{fmtUSD(b.usdValue)}</div>
                      <div className="text-[10px] text-secondary tabular">{fmtQty(b.free + b.locked, 6)} {b.asset}</div>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2 mt-3 pt-2 border-t border-border/40 text-[11px]">
                    <div>
                      <div className="text-[10px] text-secondary uppercase">Available</div>
                      <div className="tabular">{fmtQty(b.free, 6)} {b.asset}</div>
                    </div>
                    <div className="text-right">
                      <div className="text-[10px] text-secondary uppercase">Locked</div>
                      <div className="tabular text-gold">{fmtQty(b.locked, 6)} {b.asset}</div>
                    </div>
                  </div>
                  <div className="grid grid-cols-2 gap-2 mt-2">
                    <Button
                      size="sm"
                      variant="outline"
                      className="h-8 text-[11px] text-primary border-primary/30 hover:bg-primary/10"
                      onClick={() => toast.info(`Deposit ${b.asset}`, { description: `Generate ${meta?.chains[0] ?? "chain"} address` })}
                    >
                      <ArrowDownToLine className="w-3 h-3 mr-1" /> Deposit
                    </Button>
                    <Button
                      size="sm"
                      variant="outline"
                      className="h-8 text-[11px] text-danger border-danger/30 hover:bg-danger/10"
                      onClick={() => toast.info(`Withdraw ${b.asset}`)}
                    >
                      <ArrowUpFromLine className="w-3 h-3 mr-1" /> Withdraw
                    </Button>
                  </div>
                </Card>
              );
            })}
          </div>
        </TabsContent>

        <TabsContent value="deposits" className="mt-3">
          <Card className="overflow-hidden">
            <TxTable
              rows={deposits}
              columns={[
                { key: "timestamp", label: "Time", render: (d: Deposit) => fmtDateTime(d.timestamp) },
                { key: "asset", label: "Asset", render: (d: Deposit) => d.asset },
                { key: "chain", label: "Chain", render: (d: Deposit) => d.chain },
                { key: "amount", label: "Amount", right: true, render: (d: Deposit) => `${fmtQty(d.amount, 6)} ${d.asset}` },
                { key: "address", label: "Address", render: (d: Deposit) => shortAddr(d.address) },
                { key: "txHash", label: "Tx Hash", render: (d: Deposit) => shortHash(d.txHash) },
                { key: "confirmations", label: "Conf.", right: true, render: (d: Deposit) => `${d.confirmations}/${d.requiredConfirmations}` },
                { key: "status", label: "Status", render: (d: Deposit) => <StatusBadge status={d.status} /> },
              ]}
            />
          </Card>
        </TabsContent>

        <TabsContent value="withdrawals" className="mt-3">
          <Card className="overflow-hidden">
            <TxTable
              rows={withdrawals}
              columns={[
                { key: "timestamp", label: "Time", render: (w: Withdrawal) => fmtDateTime(w.timestamp) },
                { key: "asset", label: "Asset", render: (w: Withdrawal) => w.asset },
                { key: "chain", label: "Chain", render: (w: Withdrawal) => w.chain },
                { key: "amount", label: "Amount", right: true, render: (w: Withdrawal) => `${fmtQty(w.amount, 6)} ${w.asset}` },
                { key: "fee", label: "Fee", right: true, render: (w: Withdrawal) => `${fmtQty(w.fee, 6)} ${w.asset}` },
                { key: "address", label: "Address", render: (w: Withdrawal) => shortAddr(w.address) },
                { key: "txHash", label: "Tx Hash", render: (w: Withdrawal) => w.txHash ? shortHash(w.txHash) : "—" },
                { key: "status", label: "Status", render: (w: Withdrawal) => <StatusBadge status={w.status} /> },
              ]}
            />
          </Card>
        </TabsContent>

        <TabsContent value="whitelist" className="mt-3">
          <WhitelistPanel whitelist={whitelist} />
        </TabsContent>
      </Tabs>

      {/* Chains info */}
      <Card className="p-4">
        <div className="flex items-center gap-2 mb-3">
          <Shield className="w-4 h-4 text-primary" />
          <span className="text-sm font-semibold">Supported Chains & Confirmation Requirements</span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-5 gap-2">
          {CHAINS.map((c) => (
            <div key={c.id} className="bg-elevated/40 rounded p-2">
              <div className="text-xs font-medium">{c.name}</div>
              <div className="text-[10px] text-secondary mt-0.5">
                {c.confirmations} confs · {fmtUSD(c.withdrawalFeeUSD)} fee
              </div>
            </div>
          ))}
        </div>
      </Card>
    </div>
  );
}

function getUSDPrice(asset: string, pairs: any[]) {
  if (asset === "USDT") return 1;
  const p = pairs.find((x) => x.symbol === `${asset}/USDT`);
  return p ? null : null; // simplified — uses balance.usdValue elsewhere
}

function WhitelistPanel({ whitelist }: { whitelist: ReturnType<typeof useOpenCEX.getState>["whitelist"] }) {
  const addWhitelist = useOpenCEX((s) => s.addWhitelist);
  const [adding, setAdding] = useState(false);
  const [form, setForm] = useState({ asset: "BTC", chain: "Bitcoin", address: "", label: "" });

  return (
    <Card className="overflow-hidden">
      <div className="flex items-center justify-between px-4 py-2 border-b border-border">
        <div className="flex items-center gap-2">
          <Shield className="w-4 h-4 text-primary" />
          <span className="text-sm font-semibold">Whitelisted Withdrawal Addresses</span>
        </div>
        <Button size="sm" variant="outline" onClick={() => setAdding(!adding)}>
          <Plus className="w-3 h-3 mr-1" /> Add Address
        </Button>
      </div>

      {adding && (
        <div className="p-3 bg-elevated/40 border-b border-border grid grid-cols-1 md:grid-cols-5 gap-2">
          <select
            value={form.asset}
            onChange={(e) => setForm({ ...form, asset: e.target.value })}
            className="bg-input border border-border rounded px-2 py-1.5 text-xs"
          >
            {Object.keys(ASSET_METADATA).map((a) => <option key={a} value={a}>{a}</option>)}
          </select>
          <select
            value={form.chain}
            onChange={(e) => setForm({ ...form, chain: e.target.value })}
            className="bg-input border border-border rounded px-2 py-1.5 text-xs"
          >
            {CHAINS.map((c) => <option key={c.id} value={c.name}>{c.name}</option>)}
          </select>
          <input
            placeholder="0x... or bc1q..."
            value={form.address}
            onChange={(e) => setForm({ ...form, address: e.target.value })}
            className="bg-input border border-border rounded px-2 py-1.5 text-xs md:col-span-2"
          />
          <div className="flex gap-1">
            <input
              placeholder="Label"
              value={form.label}
              onChange={(e) => setForm({ ...form, label: e.target.value })}
              className="flex-1 bg-input border border-border rounded px-2 py-1.5 text-xs"
            />
            <Button
              size="sm"
              onClick={() => {
                if (!form.address || !form.label) {
                  toast.error("Address and label required");
                  return;
                }
                addWhitelist(form);
                toast.success("Address added — 24h time-lock active");
                setAdding(false);
                setForm({ asset: "BTC", chain: "Bitcoin", address: "", label: "" });
              }}
            >
              Save
            </Button>
          </div>
        </div>
      )}

      <div className="overflow-x-auto no-scrollbar">
        <div style={{ minWidth: "640px" }}>
          <div className="grid grid-cols-12 gap-2 px-4 py-2 text-[10px] uppercase text-secondary border-b border-border">
            <span className="col-span-2">Asset</span>
            <span className="col-span-2">Chain</span>
            <span className="col-span-4">Address</span>
            <span className="col-span-2">Label</span>
            <span className="col-span-1">Time-lock</span>
            <span className="col-span-1">Added</span>
          </div>
          <div>
            {whitelist.map((w) => (
              <div key={w.id} className="grid grid-cols-12 gap-2 px-4 py-2 text-xs items-center border-b border-border/40 tabular hover:bg-elevated/40">
                <span className="col-span-2 font-medium">{w.asset}</span>
                <span className="col-span-2 text-secondary">{w.chain}</span>
                <span className="col-span-4 font-mono text-[11px]">{shortAddr(w.address, 10, 8)}</span>
                <span className="col-span-2 text-secondary">{w.label}</span>
                <span className="col-span-1 text-gold">{w.timeLockHours}h</span>
                <span className="col-span-1 text-secondary text-[10px]">{new Date(w.addedAt).toLocaleDateString()}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Card>
  );
}

interface Column<T> {
  key: string;
  label: string;
  right?: boolean;
  render: (row: T) => React.ReactNode;
}

function TxTable<T extends { id: string; timestamp: number }>({ rows, columns }: { rows: T[]; columns: Column<T>[] }) {
  // Min width so the table can horizontally scroll on mobile
  const minRowWidth = Math.max(columns.length * 110, 600);
  return (
    <div>
      <div className="overflow-x-auto no-scrollbar">
        <div style={{ minWidth: `${minRowWidth}px` }}>
          <div className="grid gap-2 px-4 py-2 text-[10px] uppercase text-secondary border-b border-border" style={{ gridTemplateColumns: `repeat(${columns.length}, minmax(0, 1fr))` }}>
            {columns.map((c) => (
              <span key={c.key} className={c.right ? "text-right" : ""}>{c.label}</span>
            ))}
          </div>
          <div className="max-h-[60vh] overflow-y-auto">
            {rows.length === 0 && <div className="px-4 py-8 text-center text-xs text-secondary">No records</div>}
            {rows.map((row) => (
              <div
                key={row.id}
                className="grid gap-2 px-4 py-2 text-xs items-center border-b border-border/40 tabular hover:bg-elevated/40"
                style={{ gridTemplateColumns: `repeat(${columns.length}, minmax(0, 1fr))` }}
              >
                {columns.map((c) => (
                  <span key={c.key} className={c.right ? "text-right" : ""}>{c.render(row)}</span>
                ))}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colorMap: Record<string, string> = {
    PENDING: "bg-yellow-500/15 text-gold",
    CONFIRMED: "bg-blue-500/15 text-blue-400",
    CREDITED: "bg-primary/15 text-primary",
    APPROVED: "bg-blue-500/15 text-blue-400",
    PROCESSING: "bg-purple-500/15 text-purple-400",
    COMPLETED: "bg-primary/15 text-primary",
    REJECTED: "bg-danger/15 text-danger",
  };
  return (
    <span className={`px-1.5 py-0.5 rounded text-[10px] font-medium ${colorMap[status] ?? "bg-elevated text-secondary"}`}>
      {status}
    </span>
  );
}
MBUNI_LOGO_EOF
