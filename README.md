# Rubrik

Rubrik is a complete and simple digital signature library that implements the PAdES standard (PDF Advanced Electronic
Signatures) in pure Ruby. It conforms with PKCS#7 and **will be** compatible with Brazil's AD-RB, AD-RT and EU's B-B
and B-T profiles.

- [Rubrik](#rubrik)
  - [Implementation Status](#implementation-status)
    - [PDF Features](#pdf-features)
    - [Signature Profiles](#signature-profiles)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Development](#development)
  - [References:](#references)
  - [Contributing](#contributing)
  - [License](#license)
  - [Code of Conduct](#code-of-conduct)

## Implementation Status

This gem is under development and may be subjected to breaking changes.

### PDF Features
- [x] Modify PDFs with incremental updates (doesn't modify the documents, only append signature appearance)
- [ ] Signature appearance (stamp)
- [ ] External (offline) signatures

### Signature Profiles
- [x] CMS (PKCS#7)
- [ ] PAdES B-B (conforms with PAdES-E-BES)
- [ ] PAdES B-T (conforms with PAdES-E-BES)
- [ ] PAdES AD-RB
- [ ] PAdES AD-RT

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add rubrik

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install rubrik

## Usage

With the gem loaded, run the following to sign an document:

```ruby
# The input and output can be of types `File`, `Tempfile` or `StringIO`.
input_pdf = File.open("example.pdf", "rb")
output_pdf = File.open("signed_example.pdf", "wb+") # needs read permission

# Load Certificate(s)
certificate = File.open("example_cert.pem", "rb")
private_key = OpenSSL::PKey::RSA.new(certificate, "")
certificate.rewind
public_key = OpenSSL::X509::Certificate.new(certificate)
certificate.close

# Will write the signed document to `output_pdf`
Rubrik::Sign.call(input_pdf, output_pdf, private_key:, public_key:, certificate_chain: [])

# Don't forget to close the files
input_pdf.close
output_pdf.close
```
Multiple signatures on a single document can be achieved by calling `Rubrik::Sign` repeatedly using the last signature
output as input for the next signature. A better API for this use case may be developed.


## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## References:
1. PDF References:
    - [ISO 3200-2](https://pdfa.org/sponsored-standards/)

2. Brazil's technical references:
    - [DOC-ICP-15.03](https://www.gov.br/iti/pt-br/assuntos/legislacao/instrucoes-normativas/IN032021_DOC_15.03_assinada.pdf)
3. EU's technical references:
    - [ETSI 319 122-1](https://www.etsi.org/deliver/etsi_en/319100_319199/31912201/01.02.01_60/en_31912201v010201p.pdf)
    - [ETSI 319 122-2](https://www.etsi.org/deliver/etsi_en/319100_319199/31912201/01.02.01_60/en_31912201v010201p.pdf)

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/tomascco/rubrik. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/tomascco/rubrik/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the rubrik project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/tomascco/rubrik/blob/main/CODE_OF_CONDUCT.md).
